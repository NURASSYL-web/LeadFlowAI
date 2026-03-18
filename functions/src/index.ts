import * as admin from "firebase-admin";
import {defineSecret} from "firebase-functions/params";
import {setGlobalOptions} from "firebase-functions/v2";
import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

admin.initializeApp();

setGlobalOptions({
  region: "us-central1",
  maxInstances: 10,
});

const whatsappVerifyToken = defineSecret("WHATSAPP_VERIFY_TOKEN");
const whatsappAccessToken = defineSecret("WHATSAPP_ACCESS_TOKEN");
const openAiApiKey = defineSecret("OPENAI_API_KEY");
const twilioAccountSid = defineSecret("TWILIO_ACCOUNT_SID");
const twilioAuthToken = defineSecret("TWILIO_AUTH_TOKEN");
const telegramBotToken = defineSecret("TELEGRAM_BOT_TOKEN");
const telegramBotUsername = defineSecret("TELEGRAM_BOT_USERNAME");
const telegramWebhookSecret = defineSecret("TELEGRAM_WEBHOOK_SECRET");

type WhatsAppTextMessage = {
  from?: string;
  id?: string;
  timestamp?: string;
  type?: string;
  text?: {
    body?: string;
  };
};

type WhatsAppContact = {
  profile?: {
    name?: string;
  };
  wa_id?: string;
};

type WhatsAppValue = {
  messaging_product?: string;
  metadata?: {
    display_phone_number?: string;
    phone_number_id?: string;
  };
  contacts?: WhatsAppContact[];
  messages?: WhatsAppTextMessage[];
};

type WhatsAppChange = {
  field?: string;
  value?: WhatsAppValue;
};

type WhatsAppEntry = {
  id?: string;
  changes?: WhatsAppChange[];
};

type WhatsAppWebhookPayload = {
  object?: string;
  entry?: WhatsAppEntry[];
};

type LeadflowService = {
  name?: string;
  price?: number | string;
  duration?: number | string;
};

type LeadflowFaq = {
  question?: string;
  answer?: string;
};

type LeadflowMessage = {
  direction?: string;
  text?: string;
};

type GenerateAiReplyRequest = {
  conversationId?: string;
  customerName?: string;
  customerMessage?: string;
  businessName?: string;
  workingHours?: string;
  services?: LeadflowService[];
  faqs?: LeadflowFaq[];
  messages?: LeadflowMessage[];
};

type SendWhatsAppReplyRequest = {
  conversationId?: string;
  text?: string;
};

type TelegramUser = {
  id?: number;
  first_name?: string;
  last_name?: string;
  username?: string;
};

type TelegramChat = {
  id?: number;
  type?: string;
  title?: string;
  username?: string;
  first_name?: string;
  last_name?: string;
};

type TelegramMessage = {
  message_id?: number;
  date?: number;
  text?: string;
  caption?: string;
  from?: TelegramUser;
  chat?: TelegramChat;
};

type TelegramUpdate = {
  update_id?: number;
  message?: TelegramMessage;
  edited_message?: TelegramMessage;
};

type TwilioWebhookPayload = {
  AccountSid?: string;
  Body?: string;
  From?: string;
  To?: string;
  ProfileName?: string;
  WaId?: string;
  MessageSid?: string;
  SmsMessageSid?: string;
};

type SalonLink = {
  salonId: string | null;
  ownerUid: string | null;
};

/**
 * Normalizes a phone number to digits only.
 * @param {string | undefined} phone Original phone value.
 * @return {string} Digits-only phone value.
 */
function normalizePhone(phone?: string): string {
  return (phone ?? "").replace(/[^\d]/g, "");
}

/**
 * Normalizes a Telegram bot handle into @username format.
 * @param {string | undefined} handle Raw bot handle.
 * @return {string} Normalized Telegram handle.
 */
function normalizeTelegramHandle(handle?: string): string {
  const trimmed = (handle ?? "").trim().replace(/^@+/, "");
  return trimmed ? `@${trimmed}` : "";
}

/**
 * Removes the whatsapp: prefix from a Twilio channel address.
 * @param {string | undefined} address WhatsApp channel address.
 * @return {string} Raw address value without channel prefix.
 */
function normalizeChannelAddress(address?: string): string {
  return (address ?? "").replace(/^whatsapp:/i, "").trim();
}

/**
 * Converts a phone number into a Twilio WhatsApp channel address.
 * @param {string | undefined} value Phone number or channel address.
 * @return {string} WhatsApp channel address.
 */
function toWhatsappAddress(value?: string): string {
  const normalized = normalizeChannelAddress(value);
  if (!normalized) {
    return "";
  }

  if (normalized.startsWith("+")) {
    return `whatsapp:${normalized}`;
  }

  const digits = normalizePhone(normalized);
  return digits ? `whatsapp:+${digits}` : "";
}

/**
 * Builds the conversation id from a phone number.
 * @param {string | undefined} phone Original phone value.
 * @return {string} Stable conversation id.
 */
function conversationId(phone?: string): string {
  const normalized = normalizePhone(phone);
  return normalized || "unknown";
}

/**
 * Builds a preview line from an inbound WhatsApp message.
 * @param {WhatsAppTextMessage} message Raw WhatsApp message.
 * @return {string} Preview text for the conversation.
 */
function buildConversationPreview(message: WhatsAppTextMessage): string {
  if (message.text?.body?.trim()) {
    return message.text.body.trim();
  }
  return message.type ? `[${message.type}]` : "[unsupported message]";
}

/**
 * Builds a preview line from an inbound Telegram message.
 * @param {TelegramMessage | undefined} message Raw Telegram message.
 * @return {string} Preview text for the conversation.
 */
function buildTelegramPreview(message?: TelegramMessage): string {
  const text = message?.text?.trim() || message?.caption?.trim();
  if (text) {
    return text;
  }
  return "[unsupported message]";
}

/**
 * Builds a stable Telegram conversation id from a chat id.
 * @param {number | undefined} chatId Telegram chat id.
 * @return {string} Stable Firestore conversation id.
 */
function telegramConversationId(chatId?: number): string {
  return chatId == null ? "telegram_unknown" : `telegram_${String(chatId)}`;
}

/**
 * Finds a salon by its WhatsApp Business number.
 * @param {string} businessPhone Business phone in digits-only format.
 * @return {Promise<Object>} Matching salon and owner identifiers.
 */
async function findSalonByBusinessNumber(
  businessPhone: string,
): Promise<SalonLink> {
  const db = admin.firestore();

  if (!businessPhone) {
    return findSingleSalonFallback();
  }

  const salonSnapshot = await db
    .collection("salons")
    .where("whatsappNumber", "==", businessPhone)
    .limit(1)
    .get();

  if (salonSnapshot.empty) {
    return findSingleSalonFallback();
  }

  const salonDoc = salonSnapshot.docs[0];
  return {
    salonId: salonDoc.id,
    ownerUid: (salonDoc.data()["ownerUid"] as string | undefined) ?? null,
  };
}

/**
 * Falls back to the only salon in the project for single-tenant demos.
 * @return {Promise<SalonLink>} Matching salon and owner identifiers.
 */
async function findSingleSalonFallback(): Promise<SalonLink> {
  const db = admin.firestore();
  const snapshot = await db
    .collection("salons")
    .limit(2)
    .get();

  if (snapshot.size !== 1) {
    const latestSnapshot = await db
      .collection("salons")
      .orderBy("createdAt", "desc")
      .limit(1)
      .get();

    if (!latestSnapshot.empty) {
      const latestSalonDoc = latestSnapshot.docs[0];
      return {
        salonId: latestSalonDoc.id,
        ownerUid:
          (latestSalonDoc.data()["ownerUid"] as string | undefined) ?? null,
      };
    }

    return {salonId: null, ownerUid: null};
  }

  const salonDoc = snapshot.docs[0];
  return {
    salonId: salonDoc.id,
    ownerUid: (salonDoc.data()["ownerUid"] as string | undefined) ?? null,
  };
}

/**
 * Finds a salon that is connected to the configured Telegram bot username.
 * @param {string | undefined} botUsername Configured Telegram bot username.
 * @return {Promise<SalonLink>} Matching salon and owner identifiers.
 */
async function findSalonByTelegramBotUsername(
  botUsername?: string,
): Promise<SalonLink> {
  const normalizedBotUsername = normalizeTelegramHandle(botUsername);
  if (!normalizedBotUsername) {
    return findSingleSalonFallback();
  }

  const snapshot = await admin.firestore()
    .collection("salons")
    .where("whatsappNumber", "==", normalizedBotUsername)
    .limit(1)
    .get();

  if (!snapshot.empty) {
    const salonDoc = snapshot.docs[0];
    return {
      salonId: salonDoc.id,
      ownerUid: (salonDoc.data()["ownerUid"] as string | undefined) ?? null,
    };
  }

  return findSingleSalonFallback();
}

/**
 * Persists inbound WhatsApp webhook payload into Firestore.
 * @param {WhatsAppWebhookPayload} payload Raw webhook payload.
 * @return {Promise<void>} Resolves when the batch commit completes.
 */
async function saveIncomingMessage(
  payload: WhatsAppWebhookPayload,
): Promise<void> {
  const db = admin.firestore();
  const batch = db.batch();

  for (const entry of payload.entry ?? []) {
    for (const change of entry.changes ?? []) {
      if (change.field !== "messages" || !change.value) {
        continue;
      }

      const value = change.value;
      const contact = value.contacts?.[0];
      const businessPhone = normalizePhone(
        value.metadata?.display_phone_number,
      );
      const ownerLink = await findSalonByBusinessNumber(businessPhone);

      for (const message of value.messages ?? []) {
        const fromPhone = normalizePhone(message.from);
        const convoId = conversationId(fromPhone);
        const messageId = message.id ?? db.collection("_").doc().id;
        const timestampMs = Number(message.timestamp ?? "0") * 1000;
        const createdAt = timestampMs > 0 ?
          admin.firestore.Timestamp.fromMillis(timestampMs) :
          admin.firestore.Timestamp.now();
        const preview = buildConversationPreview(message);

        const conversationRef = db.collection("conversations").doc(convoId);
        const messageRef = conversationRef
          .collection("messages")
          .doc(messageId);

        batch.set(conversationRef, {
          conversationId: convoId,
          salonId: ownerLink.salonId,
          ownerUid: ownerLink.ownerUid,
          customerPhone: fromPhone,
          customerPhoneE164: fromPhone ? `+${fromPhone}` : null,
          customerName: contact?.profile?.name ?? "WhatsApp user",
          channel: "whatsapp",
          provider: "meta",
          integration: "meta_cloud_api",
          lastMessage: preview,
          lastMessageAt: createdAt,
          unreadCount: admin.firestore.FieldValue.increment(1),
          phoneNumberId: value.metadata?.phone_number_id ?? null,
          displayPhoneNumber: value.metadata?.display_phone_number ?? null,
          displayPhoneNumberNormalized: businessPhone,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});

        batch.set(messageRef, {
          messageId,
          conversationId: convoId,
          from: fromPhone,
          direction: "inbound",
          type: message.type ?? "unknown",
          text: message.text?.body ?? "",
          raw: message,
          createdAt,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
      }
    }
  }

  await batch.commit();
}

/**
 * Parses the x-www-form-urlencoded payload that Twilio sends to webhooks.
 * @param {unknown} body Parsed request body.
 * @param {Buffer | undefined} rawBody Raw request body.
 * @return {TwilioWebhookPayload} Parsed webhook payload.
 */
function parseTwilioWebhookPayload(
  body: unknown,
  rawBody?: Buffer,
): TwilioWebhookPayload {
  if (body && typeof body === "object" && !Array.isArray(body)) {
    const data = body as Record<string, unknown>;
    return {
      AccountSid: typeof data["AccountSid"] === "string" ?
        data["AccountSid"] :
        undefined,
      Body: typeof data["Body"] === "string" ? data["Body"] : undefined,
      From: typeof data["From"] === "string" ? data["From"] : undefined,
      To: typeof data["To"] === "string" ? data["To"] : undefined,
      ProfileName: typeof data["ProfileName"] === "string" ?
        data["ProfileName"] :
        undefined,
      WaId: typeof data["WaId"] === "string" ? data["WaId"] : undefined,
      MessageSid: typeof data["MessageSid"] === "string" ?
        data["MessageSid"] :
        undefined,
      SmsMessageSid: typeof data["SmsMessageSid"] === "string" ?
        data["SmsMessageSid"] :
        undefined,
    };
  }

  const params = new URLSearchParams(rawBody?.toString("utf8") ?? "");
  return {
    AccountSid: params.get("AccountSid") ?? undefined,
    Body: params.get("Body") ?? undefined,
    From: params.get("From") ?? undefined,
    To: params.get("To") ?? undefined,
    ProfileName: params.get("ProfileName") ?? undefined,
    WaId: params.get("WaId") ?? undefined,
    MessageSid: params.get("MessageSid") ?? params.get("SmsMessageSid") ??
      undefined,
  };
}

/**
 * Persists an inbound Twilio WhatsApp message into Firestore.
 * @param {TwilioWebhookPayload} payload Twilio webhook payload.
 * @return {Promise<void>} Resolves when the write finishes.
 */
async function saveIncomingTwilioMessage(
  payload: TwilioWebhookPayload,
): Promise<void> {
  const body = payload.Body?.trim();
  const fromAddress = normalizeChannelAddress(payload.From);
  const toAddress = normalizeChannelAddress(payload.To);
  const customerPhone = normalizePhone(payload.WaId) ||
    normalizePhone(fromAddress);

  if (!customerPhone || !body) {
    logger.info("Skipping unsupported Twilio payload", {payload});
    return;
  }

  const convoId = conversationId(customerPhone);
  const db = admin.firestore();
  const conversationRef = db.collection("conversations").doc(convoId);
  const messageId = payload.MessageSid?.trim() || db.collection("_").doc().id;
  const messageRef = conversationRef.collection("messages").doc(messageId);
  const ownerLink = await findSalonByBusinessNumber(normalizePhone(toAddress));

  await conversationRef.set({
    conversationId: convoId,
    salonId: ownerLink.salonId,
    ownerUid: ownerLink.ownerUid,
    customerPhone,
    customerPhoneE164: customerPhone ? `+${customerPhone}` : null,
    customerName: payload.ProfileName?.trim() || "WhatsApp user",
    channel: "whatsapp",
    provider: "twilio",
    integration: "twilio_sandbox",
    lastMessage: body,
    lastMessageAt: admin.firestore.Timestamp.now(),
    unreadCount: admin.firestore.FieldValue.increment(1),
    displayPhoneNumber: toAddress || null,
    displayPhoneNumberNormalized: normalizePhone(toAddress),
    twilioAccountSid: payload.AccountSid?.trim() || null,
    twilioToAddress: payload.To?.trim() || null,
    customerAddress: payload.From?.trim() || null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  await messageRef.set({
    messageId,
    conversationId: convoId,
    from: customerPhone,
    direction: "inbound",
    type: "text",
    text: body,
    raw: payload,
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
}

/**
 * Persists an inbound Telegram update into Firestore.
 * @param {TelegramUpdate} update Telegram webhook update.
 * @return {Promise<void>} Resolves when the write finishes.
 */
async function saveIncomingTelegramMessage(
  update: TelegramUpdate,
): Promise<void> {
  const message = update.message ?? update.edited_message;
  const chatId = message?.chat?.id;
  const preview = buildTelegramPreview(message);

  if (chatId == null || preview === "[unsupported message]") {
    logger.info("Skipping unsupported Telegram payload", {update});
    return;
  }

  const db = admin.firestore();
  const convoId = telegramConversationId(chatId);
  const conversationRef = db.collection("conversations").doc(convoId);
  const messageId = String(message?.message_id ?? db.collection("_").doc().id);
  const messageRef = conversationRef.collection("messages").doc(messageId);
  const configuredBotUsername = normalizeTelegramHandle(
    telegramBotUsername.value(),
  );
  const ownerLink = await findSalonByTelegramBotUsername(configuredBotUsername);
  const customerName = [
    message?.from?.first_name,
    message?.from?.last_name,
  ].filter((part): part is string => Boolean(part && part.trim())).join(" ");
  const displayName = customerName.trim().length > 0 ?
    customerName.trim() :
    message?.from?.username?.trim() || "Telegram user";
  const createdAt = message?.date != null ?
    admin.firestore.Timestamp.fromMillis(message.date * 1000) :
    admin.firestore.Timestamp.now();

  logger.info("Linking Telegram conversation", {
    conversationId: convoId,
    telegramBotUsername: configuredBotUsername || null,
    salonId: ownerLink.salonId,
    ownerUid: ownerLink.ownerUid,
  });

  await conversationRef.set({
    conversationId: convoId,
    salonId: ownerLink.salonId,
    ownerUid: ownerLink.ownerUid,
    customerPhone: message?.from?.username?.trim() ?
      `@${message?.from?.username?.trim()}` :
      String(message?.from?.id ?? chatId),
    customerName: displayName,
    channel: "telegram",
    provider: "telegram",
    integration: "telegram_bot",
    lastMessage: preview,
    lastMessageAt: createdAt,
    unreadCount: admin.firestore.FieldValue.increment(1),
    telegramChatId: chatId,
    telegramMessageId: message?.message_id ?? null,
    telegramUsername: message?.from?.username?.trim() || null,
    telegramChatType: message?.chat?.type ?? null,
    telegramBotUsername: configuredBotUsername || null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  await messageRef.set({
    messageId,
    conversationId: convoId,
    from: String(message?.from?.id ?? chatId),
    direction: "inbound",
    type: "text",
    text: preview,
    raw: update,
    createdAt,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
}

/**
 * Builds the LLM prompt from business and conversation context.
 * @param {GenerateAiReplyRequest} body Request payload from the app.
 * @return {string} Prompt text for the model.
 */
function buildAiPrompt(body: GenerateAiReplyRequest): string {
  const serviceLines = (body.services ?? [])
    .map((service) => {
      const price = service.price == null ? "" : `, price: ${service.price}`;
      const duration =
        service.duration == null ? "" : `, duration: ${service.duration} min`;
      return `- ${service.name ?? "Service"}${price}${duration}`;
    })
    .join("\n");

  const faqLines = (body.faqs ?? [])
    .map((faq) => `Q: ${faq.question ?? ""}\nA: ${faq.answer ?? ""}`)
    .join("\n\n");
  const messageLines = (body.messages ?? [])
    .map(
      (message) =>
        `${message.direction ?? "unknown"}: ${message.text ?? ""}`,
    )
    .filter((line) => line.trim().length > 0)
    .join("\n");

  return [
    "You are the live sales and support assistant for a beauty salon.",
    "Read the customer message carefully and write a natural reply",
    "that feels human, specific, and ready to send in Telegram.",
    "Do not mention being AI. Do not sound generic.",
    "Do not invent unavailable services or prices.",
    "Keep the reply concise, warm, and business-ready.",
    `Business name: ${body.businessName ?? "LeadFlow AI"}`,
    `Working hours: ${body.workingHours ?? "Not provided"}`,
    `Customer name: ${body.customerName ?? "Customer"}`,
    serviceLines.length === 0 ?
      "Services: not provided" :
      `Services:\n${serviceLines}`,
    faqLines.length === 0 ? "FAQs: not provided" : `FAQs:\n${faqLines}`,
    messageLines.length === 0 ?
      "Conversation history: not provided" :
      `Conversation history:\n${messageLines}`,
    `Customer message:\n${body.customerMessage ?? ""}`,
    "Return only the final reply text.",
  ].join("\n\n");
}

/**
 * Requests a real reply from the OpenAI Responses API.
 * @param {GenerateAiReplyRequest} body Request payload from the app.
 * @return {Promise<string>} Final reply text for WhatsApp.
 */
async function requestAiReply(body: GenerateAiReplyRequest): Promise<string> {
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${openAiApiKey.value()}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "gpt-4.1-mini",
      input: buildAiPrompt(body),
    }),
  });

  const payload = await response.json() as {
    output_text?: string;
    error?: {
      message?: string;
    };
  };

  if (!response.ok) {
    throw new Error(payload.error?.message ?? "OpenAI request failed");
  }

  const reply = payload.output_text?.trim();
  if (!reply) {
    throw new Error("OpenAI returned an empty reply");
  }

  return reply;
}

export const generateAiReply = onRequest(
  {
    secrets: [openAiApiKey],
    invoker: "public",
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    try {
      const body = req.body as GenerateAiReplyRequest;
      const reply = await requestAiReply(body);

      if (body.conversationId?.trim()) {
        await admin.firestore()
          .collection("conversations")
          .doc(body.conversationId.trim())
          .set({
            suggestedReply: reply,
            aiGeneratedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, {merge: true});
      }

      res.status(200).json({reply});
    } catch (error) {
      logger.error("Failed to generate AI reply", error);
      res.status(500).json({
        error: error instanceof Error ?
          error.message :
          "Failed to generate AI reply",
      });
    }
  },
);

export const sendWhatsAppReply = onRequest(
  {
    secrets: [whatsappAccessToken, twilioAccountSid, twilioAuthToken],
    invoker: "public",
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    try {
      const body = req.body as SendWhatsAppReplyRequest;
      const conversationIdValue = body.conversationId?.trim();
      const text = body.text?.trim();

      if (!conversationIdValue || !text) {
        res.status(400).json({error: "conversationId and text are required"});
        return;
      }

      const db = admin.firestore();
      const conversationRef = db
        .collection("conversations")
        .doc(conversationIdValue);
      const conversationSnapshot = await conversationRef.get();

      if (!conversationSnapshot.exists) {
        res.status(404).json({error: "Conversation not found"});
        return;
      }

      const conversation = conversationSnapshot.data() ?? {};
      const provider = (conversation["provider"] as string | undefined)?.trim();
      const phoneNumberId =
        (conversation["phoneNumberId"] as string | undefined)?.trim();
      const customerPhone = normalizePhone(
        conversation["customerPhone"] as string | undefined,
      );
      const displayPhoneNumber =
        (conversation["displayPhoneNumber"] as string | undefined) ?? null;
      const displayPhoneNumberNormalized = normalizePhone(
        displayPhoneNumber ?? undefined,
      );

      let messageId = db.collection("_").doc().id;
      let outboundFrom = displayPhoneNumberNormalized;

      if (provider === "twilio") {
        const accountSid = twilioAccountSid.value().trim();
        const authToken = twilioAuthToken.value().trim();
        const twilioFrom =
          (conversation["twilioToAddress"] as string | undefined)?.trim() ||
          "whatsapp:+14155238886";
        const customerAddress =
          (conversation["customerAddress"] as string | undefined)?.trim() ||
          toWhatsappAddress(
            (conversation["customerPhoneE164"] as string | undefined) ??
            customerPhone,
          );

        if (!accountSid || !authToken || !customerAddress) {
          res.status(400).json({
            error:
              "Twilio conversation is missing credentials or customer address",
          });
          return;
        }

        const twilioResponse = await fetch(
          `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
          {
            method: "POST",
            headers: {
              "Authorization": `Basic ${Buffer
                .from(`${accountSid}:${authToken}`)
                .toString("base64")}`,
              "Content-Type": "application/x-www-form-urlencoded",
            },
            body: new URLSearchParams({
              From: twilioFrom,
              To: customerAddress,
              Body: text,
            }).toString(),
          },
        );

        const twilioPayload = await twilioResponse.json() as {
          sid?: string;
          message?: string;
        };

        if (!twilioResponse.ok) {
          throw new Error(twilioPayload.message ?? "Twilio send failed");
        }

        messageId = twilioPayload.sid ?? messageId;
        outboundFrom = normalizePhone(twilioFrom);
      } else {
        if (!phoneNumberId || !customerPhone) {
          res.status(400).json({
            error: "Conversation is missing phoneNumberId or customerPhone",
          });
          return;
        }

        const graphResponse = await fetch(
          `https://graph.facebook.com/v23.0/${phoneNumberId}/messages`,
          {
            method: "POST",
            headers: {
              "Authorization": `Bearer ${whatsappAccessToken.value()}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              messaging_product: "whatsapp",
              recipient_type: "individual",
              to: customerPhone,
              type: "text",
              text: {
                preview_url: false,
                body: text,
              },
            }),
          },
        );

        const graphPayload = await graphResponse.json() as {
          error?: {
            message?: string;
          };
          messages?: Array<{
            id?: string;
          }>;
        };

        if (!graphResponse.ok) {
          throw new Error(
            graphPayload.error?.message ?? "WhatsApp send failed",
          );
        }

        messageId = graphPayload.messages?.[0]?.id ?? messageId;
      }

      await conversationRef.collection("messages").doc(messageId).set({
        messageId,
        conversationId: conversationIdValue,
        from: outboundFrom,
        direction: "outbound",
        type: "text",
        text,
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      await conversationRef.set({
        lastMessage: text,
        lastMessageAt: admin.firestore.Timestamp.now(),
        suggestedReply: text,
        unreadCount: 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      res.status(200).json({messageId});
    } catch (error) {
      logger.error("Failed to send WhatsApp reply", error);
      res.status(500).json({
        error: error instanceof Error ?
          error.message :
          "Failed to send WhatsApp reply",
      });
    }
  },
);

export const sendTelegramReply = onRequest(
  {
    secrets: [telegramBotToken],
    invoker: "public",
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    try {
      const body = req.body as SendWhatsAppReplyRequest;
      const conversationIdValue = body.conversationId?.trim();
      const text = body.text?.trim();

      if (!conversationIdValue || !text) {
        res.status(400).json({error: "conversationId and text are required"});
        return;
      }

      const db = admin.firestore();
      const conversationRef = db
        .collection("conversations")
        .doc(conversationIdValue);
      const conversationSnapshot = await conversationRef.get();

      if (!conversationSnapshot.exists) {
        res.status(404).json({error: "Conversation not found"});
        return;
      }

      const conversation = conversationSnapshot.data() ?? {};
      const chatId = conversation["telegramChatId"] as number | undefined;
      const botToken = telegramBotToken.value().trim();

      if (!botToken || chatId == null) {
        res.status(400).json({
          error: "Conversation is missing telegramChatId or bot token",
        });
        return;
      }

      const telegramResponse = await fetch(
        `https://api.telegram.org/bot${botToken}/sendMessage`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            chat_id: chatId,
            text,
          }),
        },
      );

      const telegramPayload = await telegramResponse.json() as {
        ok?: boolean;
        description?: string;
        result?: {
          message_id?: number;
        };
      };

      if (!telegramResponse.ok || telegramPayload.ok != true) {
        throw new Error(
          telegramPayload.description ?? "Telegram send failed",
        );
      }

      const messageId = String(
        telegramPayload.result?.message_id ?? db.collection("_").doc().id,
      );

      await conversationRef.collection("messages").doc(messageId).set({
        messageId,
        conversationId: conversationIdValue,
        from: "bot",
        direction: "outbound",
        type: "text",
        text,
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      await conversationRef.set({
        lastMessage: text,
        lastMessageAt: admin.firestore.Timestamp.now(),
        suggestedReply: text,
        unreadCount: 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      res.status(200).json({messageId});
    } catch (error) {
      logger.error("Failed to send Telegram reply", error);
      res.status(500).json({
        error: error instanceof Error ?
          error.message :
          "Failed to send Telegram reply",
      });
    }
  },
);

export const telegramWebhook = onRequest(
  {
    secrets: [telegramWebhookSecret, telegramBotUsername],
    invoker: "public",
    serviceAccount: "leadflow-9d3b0@appspot.gserviceaccount.com",
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const expectedSecret = telegramWebhookSecret.value().trim();
    const headerSecret =
      req.get("X-Telegram-Bot-Api-Secret-Token")?.trim() ?? "";

    if (expectedSecret.length > 0 && headerSecret != expectedSecret) {
      logger.warn("Telegram webhook verification failed");
      res.status(403).send("Forbidden");
      return;
    }

    const update = req.body as TelegramUpdate;
    logger.info("Telegram webhook received", {update});

    try {
      await saveIncomingTelegramMessage(update);
      res.status(200).type("text/plain").send("OK");
    } catch (error) {
      logger.error("Failed to process Telegram webhook", error);
      res.status(500).send("Webhook processing failed");
    }
  },
);

export const twilioWhatsappWebhook = onRequest(
  {
    invoker: "public",
    serviceAccount: "leadflow-9d3b0@appspot.gserviceaccount.com",
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const payload = parseTwilioWebhookPayload(req.body, req.rawBody);
    logger.info("Twilio WhatsApp webhook received", {payload});

    try {
      await saveIncomingTwilioMessage(payload);
      res.status(200).type("text/plain").send("OK");
    } catch (error) {
      logger.error("Failed to process Twilio webhook", error);
      res.status(500).send("Webhook processing failed");
    }
  },
);

export const whatsappWebhook = onRequest(
  {
    secrets: [whatsappVerifyToken],
    invoker: "public",
    serviceAccount: "leadflow-9d3b0@appspot.gserviceaccount.com",
  },
  async (req, res) => {
    if (req.method === "GET") {
      const mode = req.query["hub.mode"];
      const token = req.query["hub.verify_token"];
      const challenge = req.query["hub.challenge"];
      const expectedToken = whatsappVerifyToken.value();

      if (
        mode === "subscribe" &&
        token === expectedToken &&
        typeof challenge === "string"
      ) {
        logger.info("WhatsApp webhook verified");
        res.status(200).send(challenge);
        return;
      }

      logger.warn("WhatsApp webhook verification failed");
      res.status(403).send("Forbidden");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const payload = req.body as WhatsAppWebhookPayload;
    logger.info("WhatsApp webhook received", {payload});

    try {
      await saveIncomingMessage(payload);
      res.status(200).send("EVENT_RECEIVED");
    } catch (error) {
      logger.error("Failed to process WhatsApp webhook", error);
      res.status(500).send("Webhook processing failed");
    }
  },
);

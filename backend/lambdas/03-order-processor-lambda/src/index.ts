import type { SQSBatchResponse, SQSEvent, SQSRecord } from "aws-lambda";
import { getOrderProcessor } from "./processors/index.js";
import type { OrderEvent } from "./processors/types.js";

const required = (order: Record<string, unknown>, field: keyof OrderEvent): void => {
  if (order[field] === undefined || order[field] === null || order[field] === "") {
    throw new Error(`Order event field ${field} is required.`);
  }
};

const correlationIdFrom = (record: SQSRecord): string | undefined => {
  try {
    const body = JSON.parse(record.body) as { correlationId?: unknown };
    return typeof body.correlationId === "string" && body.correlationId.length > 0
      ? body.correlationId
      : undefined;
  } catch {
    return undefined;
  }
};

const parseOrder = (record: SQSRecord): OrderEvent => {
  const order = JSON.parse(record.body) as Record<string, unknown>;
  const requiredFields: (keyof OrderEvent)[] = [
    "orderId",
    "buyerId",
    "sellerId",
    "productId",
    "quantity",
    "occurredAt",
    "idempotencyKey",
  ];
  requiredFields.forEach((field) => required(order, field));
  return order as OrderEvent;
};

export const handler = async (event: SQSEvent): Promise<SQSBatchResponse> => {
  const processor = await getOrderProcessor();
  const batchItemFailures: SQSBatchResponse["batchItemFailures"] = [];

  for (const record of event.Records) {
    const correlationId = correlationIdFrom(record);
    try {
      const order = parseOrder(record);
      const result = await processor.process(order);
      console.info("order-processed", {
        messageId: record.messageId,
        orderId: order.orderId,
        idempotencyKey: order.idempotencyKey,
        correlationId: order.correlationId,
        result,
      });
    } catch (error) {
      const failure = error instanceof Error ? error : new Error("Unknown error");
      console.error("order-processing-failed", {
        messageId: record.messageId,
        correlationId,
        message: failure.message,
        stack: failure.stack,
      });
      batchItemFailures.push({ itemIdentifier: record.messageId });
    }
  }

  return { batchItemFailures };
};

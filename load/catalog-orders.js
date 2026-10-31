import http from "k6/http";
import { check, sleep } from "k6";
import { Counter } from "k6/metrics";

const stockConflicts = new Counter("order_stock_conflicts");

const apiUrl = (__ENV.K6_API_URL || "").replace(/\/$/, "");
const vus = Number.parseInt(__ENV.K6_VUS || "1", 10);
const duration = __ENV.K6_DURATION || "2m";

if (!Number.isInteger(vus) || vus < 1) {
  throw new Error("K6_VUS must be a positive integer, for example 1, 2, or 5.");
}

export const options = {
  scenarios: {
    catalog_and_orders: {
      executor: "constant-vus",
      vus,
      duration,
      gracefulStop: "10s",
    },
  },
  summaryTrendStats: ["avg", "med", "p(95)", "p(99)", "max"],
};

export function setup() {
  const token = __ENV.K6_ID_TOKEN;
  if (!apiUrl) throw new Error("K6_API_URL is empty.");
  if (!token) throw new Error("K6_ID_TOKEN is empty. Sign-in did not return a token.");

  const list = http.get(`${apiUrl}/products`, { headers: auth(token), tags: { name: "GET /products" } });
  if (list.status !== 200) {
    throw new Error(`GET /products returned ${list.status} before the ramp started.`);
  }

  const items = list.json("items") || [];
  const requestedId = __ENV.K6_PRODUCT_ID;
  const product = requestedId
    ? items.find((item) => item.id === requestedId)
    : items.slice().sort((left, right) => right.stock - left.stock)[0];

  if (!product) {
    throw new Error(requestedId ? `Product ${requestedId} is not in the catalog.` : "The catalog is empty.");
  }

  console.log(`${vus} users for ${duration}; product ${product.id} stock ${product.stock}`);
  return { token, productId: product.id };
}

export default function (data) {
  const headers = auth(data.token);
  const list = http.get(`${apiUrl}/products`, { headers, tags: { name: "GET /products" } });
  check(list, { "catalog 200": (response) => response.status === 200 });

  if (__ITER % 4 === 0) {
    const order = http.post(
      `${apiUrl}/orders`,
      JSON.stringify({ productId: data.productId, quantity: 1 }),
      { headers, tags: { name: "POST /orders" } },
    );
    check(order, { "order 202": (response) => response.status === 202 });
    if (order.status === 409) stockConflicts.add(1);
  }

  sleep(0.3);
}

function auth(token) {
  return {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
  };
}

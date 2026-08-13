# Discourse Brandme Community Access Plugin

**Plugin Summary**

This Discourse plugin integrates with the **BrandMe Shopify app** to automatically manage access to Discourse communities based on Shopify product purchases and refunds.

## Features

* Receives authenticated purchase and refund events from the BrandMe Shopify app.
* Maps Shopify products to Discourse groups through Discourse admin settings.
* Adds existing Discourse users to the appropriate group after a qualifying purchase.
* Sends new users a Discourse invitation that includes membership in the mapped group.
* Removes users from the mapped group when a qualifying purchase is refunded.
* Revokes pending invitations associated with refunded access.
* Prevents duplicate webhook events from being processed more than once.
* Maintains access logs for webhook processing and membership changes.
* Secures requests using **HMAC-SHA256 signatures**.
* Uses timestamp validation to protect against replay attacks.

## Purchase Flow

When the plugin receives a `purchase` event:

1. It validates the request signature and timestamp.
2. It checks whether the webhook has already been processed.
3. It finds the Discourse group mapped to the purchased Shopify product.
4. If a Discourse user with the customer's email already exists, the user is added to the mapped group.
5. If the user does not exist, a Discourse invitation is created with membership in the mapped group.
6. The event is recorded to prevent duplicate processing.

## Refund Flow

When the plugin receives a `refund` event:

1. It validates and deduplicates the webhook.
2. It finds the group mapped to the refunded Shopify product.
3. If the customer already has a Discourse account, the user is removed from the mapped group.
4. Any applicable pending invitations are revoked.
5. The event is recorded to prevent duplicate processing.

## Product-to-Group Mapping

Product mappings are configured from the Discourse admin settings.

Each Shopify product ID is mapped to a Discourse group, allowing different membership products to grant access to different groups.

Example:

```text
123456789=creator_members
987654321=premium_members
```

Multiple mappings are separated using `|`:

```text
123456789=creator_members|987654321=premium_members
```

## Security

Communication between the Shopify app and the Discourse plugin is authenticated using a shared connection secret.

Each request includes:

* `X-BrandMe-Timestamp`
* `X-BrandMe-Signature`

The signature is generated using **HMAC-SHA256** over the timestamp and raw request body:

```text
HMAC-SHA256(
  connectionSecret,
  timestamp + "." + rawRequestBody
)
```

The plugin independently calculates the expected signature and performs a secure comparison before processing the request.

Requests with expired timestamps or timestamps too far in the future are rejected, reducing the risk of replay attacks.

Processed webhook IDs are also stored so duplicate Shopify webhook deliveries do not cause duplicate membership operations.

## Supported Events

The plugin currently supports:

```text
purchase
refund
```

A `purchase` event grants access, while a `refund` event revokes the corresponding access.

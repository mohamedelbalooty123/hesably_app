# Offline Sync

## What is the rule?
Offline capture is permitted. Receipts captured offline are saved to a local pending queue (e.g., using Hive or SQLite) and marked as syncing when network restores. AI processing requires online connection.

## Why does it exist?
MVP requirement: shop owners may have poor connection at the point of sale.

## Where does it apply?
lib/core/database/ (local queue) and lib/features/receipt_capture/ (sync logic).

## Example
Receipt saved locally -> State: PENDING. Internet restores -> upload image -> State: SYNCING. AI processes -> State: REVIEW_REQUIRED.

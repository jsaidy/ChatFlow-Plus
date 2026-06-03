# Reliability Guarantees

## Mechanisms
- **Supervision Tree:** One-for-one restart
- **Retry Logic:** Max 3 retries
- **Timeout:** 5 seconds
- **Node Failure:** Tasks reassigned to alive nodes

## Guarantees
| Scenario | Behavior |
|----------|----------|
| Worker crash | Restart + reassign |
| Node crash | Tasks move to alive nodes |
| Timeout | Retry up to 3x |
| Message loss | At-least-once |

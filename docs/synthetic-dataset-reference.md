[← Back to main README](../README.md)

# Synthetic Dataset Reference

## Master Data

- Stores: `200`
- Products: `100`

## January 2026

- Headers: `308,269`
- Lines: `616,327`

### Header Status

- Completed: `302,029`
- Cancelled: `4,687`
- Pending: `1,553`

### Quantity

- NULL Quantity Lines: `31,199`

### Headers With Zero Valid Lines

- 1 line, and the line has NULL Quantity: `5,258`
- 2 lines, and both lines have NULL Quantity: `266`
- 3 lines, and all lines have NULL Quantity: `12`
- Total Headers With Zero Valid Lines: `5,536`

## February 2026

- Headers: `276,468`
- Lines: `553,238`

### Header Status

- Completed: `270,962`
- Cancelled: `4,069`
- Pending: `1,437`

### Quantity

- NULL Quantity Lines: `27,520`

### Headers With Zero Valid Lines

- 1 line, and the line has NULL Quantity: `4,474`
- 2 lines, and both lines have NULL Quantity: `229`
- 3 lines, and all lines have NULL Quantity: `17`
- Total Headers With Zero Valid Lines: `4,720`

## Controlled Status Updates

### January Invoices Updated During February

- Pending → Completed: `1,320`
- Pending → Cancelled: `155`
- Remaining Pending: `78`
- Total January Update Events: `1,475`

### February Invoices Updated During February

- Pending → Completed: `1,221`
- Pending → Cancelled: `143`
- Remaining Pending: `73`
- Total February Update Events: `1,364`

## Update File

- Total Header Update Events: `2,839`

## Full Generated Dataset

- Total Headers: `584,737`
- Total Lines: `1,169,565`
- Total NULL Quantity Lines: `58,719`
- Total Headers With Zero Valid Lines: `10,256`

---

[← Back to main README](../README.md)

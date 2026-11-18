# Dashboard spec: Magist premium tech, test channel not launch channel

Build in Tableau Public from the CSVs in `../data/`. One dashboard, read top to bottom in about 60 seconds. Every chart title states the finding, not the metric.

## Canvas

- Size: fixed, 1200 x 1600 px (scrolls on the Tableau Public page, reads well when embedded in the README and the website).
- Font: Tableau Book for body, Tableau Semibold for titles. Titles 15 pt, axis labels 9 pt.
- Colour: one accent for premium tech (a strong teal or orange, your choice, used nowhere else). Other tech in mid grey, non-tech in light grey. Late deliveries in a muted red. No rainbow palettes.
- Gridlines off or very light. No borders around sheets.

## Layout

```
+---------------------------------------------------------------+
| Title + one-line answer                                        |
+---------------------------------------------------------------+
| KPI 1        | KPI 2        | KPI 3          | KPI 4           |
+---------------------------------------------------------------+
| A. Demand: Magist stopped growing (line)                       |
+-------------------------------+-------------------------------+
| B. Tech here is cheap         | C. Premium supply is one       |
|    (price bands)              |    seller deep (Pareto)        |
+-------------------------------+-------------------------------+
| D. Premium parcels are the slowest (histogram, 14-day line)    |
+-------------------------------+-------------------------------+
| E. Late = 2-star review       | F. The North waits 3+ weeks    |
|    (bars)                     |    (map)                       |
+---------------------------------------------------------------+
| Footer: data window, definitions, link to GitHub               |
+---------------------------------------------------------------+
```

## Header

- **Title:** Should Eniac sell premium tech on Magist?
- **Subtitle:** Yes, as a 12-month test. The demand is small and delivery is too slow for premium buyers, but the category has no strong seller yet.

## KPI tiles

Plain text tiles (big number, one line underneath). Hard-code from the README or calculate from the CSVs.

| Tile | Number | Line underneath | Source |
|---|---|---|---|
| 1 | 35 | premium tech items sold a month, whole marketplace (2018) | monthly_tech.csv, AVG(premium_tech_items) for 2018 |
| 2 | €31.9k | premium tech revenue a month (2018) | monthly_tech.csv, AVG(premium_tech_revenue) for 2018 |
| 3 | 61% | of premium tech orders arrive within 14 days | delivery_by_segment.csv |
| 4 | 2.2 | average review when a premium order is late (4.2 when on time) | reviews_by_delivery.csv |

## Sheets

### A. Demand: "Magist stopped growing in 2018. Premium tech never took off."
- Data: `monthly_orders.csv` (orders) and `monthly_tech.csv` (premium_tech_items). Build two sheets with `month` as a continuous month on Columns and stack them on the dashboard, orders on top. Not a dual axis: the scales are 200x apart.
- Marks: line. Orders in grey, premium tech in the accent colour.
- Annotate Nov 2017: "Black Friday: 7,544 orders, only 25 premium tech items".
- Annotate the 2018 band: "6,200 to 7,300 orders a month".

### B. Price: "Half of all tech sold costs €50 or less."
- Data: `tech_price_bands.csv`
- Columns: `price_band` (sorts correctly because of the 1. to 6. prefix). Rows: `pct_of_tech_items`.
- Marks: bar. Colour by `premium` (accent for premium, grey for not premium).
- Label bars with the percentage. Caption: "Tech items average €110, below the marketplace average of €121."

### C. Sellers: "One seller makes 27% of premium tech sales."
- Data: `premium_sellers.csv`
- Horizontal bar chart of the top 10 sellers. `premium_items` on Columns, `seller` on Rows, sorted descending, Filter on seller: Top 10 by premium_items.
- Aliases on seller: Seller 1 to Seller 10 (the IDs mean nothing to a reader).
- Colour: calculated field `IF [Seller] = "53243585" THEN "Top seller" ELSE "Others" END`, accent for the top seller, grey for the rest.
- Label: `pct_of_premium_items`, number format `0.0"%"`.
- Caption: "91 sellers sold premium tech. The top 3 hold 40%, the other 81 share 44%."

### D. Delivery speed: "Premium tech is the slowest parcel on Magist."
- Data: `delivery_days_distribution.csv`
- Filter `segment` to premium tech and non-tech.
- Columns: `delivery_days` (dimension, 0 to 60). Rows: percent of total of `delivered_orders`, computed within each segment (Table calculation: Percent of Total, compute using `delivery_days`).
- Marks: bar (or area), colour by segment. Reference line at 14 days labelled "14-day promise".
- Caption: "61% of premium tech orders arrive within 14 days, vs 72% of non-tech orders. Average 15.5 vs 12.4 days."

### E. Reviews: "A late parcel turns a 4-star customer into a 2-star one."
- Data: `reviews_by_delivery.csv`
- Columns: `segment`. Rows: `avg_review_score`. Colour: `delivery` (on time grey, late red).
- Marks: side-by-side bars, labels on bars, axis 1 to 5.
- Caption: "64% of late premium tech orders get 1 or 2 stars."

### F. Geography: "The North waits more than three weeks."
- Data: `delivery_by_state.csv`
- Geographic role: `state_name` as State/Province, country Brazil.
- Marks: filled map, colour `avg_actual_days` (sequential, single hue). Tooltip: state, delivered orders, average days, % on time.
- Caption: "North 22.5 days vs São Paulo 8.7. Roraima is slowest at 29.3. On-time rates stay high because the promises in the North are longer, which is why the test uses a fixed 14-day promise."

## Footer text

> Data: Magist marketplace (WBS Coding School version of the public Olist dataset), 99,441 orders, Sep 2016 to Aug 2018. Premium tech = tech item above €500. On time = delivered on or before the promised date. Code and method: github.com/samer-odeh

## Publishing checklist

1. Save to Tableau Public as `Magist premium tech market entry`.
2. In the workbook settings, allow "Show Viz on Profile" and turn on download so reviewers can open it.
3. Take a 1600 px wide screenshot, save as `dashboard/dashboard.png` in the repo. The README embeds it.
4. Paste the Tableau Public link into the README (replace `TABLEAU_LINK`).

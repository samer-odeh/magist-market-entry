# Should Eniac sell premium tech on Magist?

**Answer: use Magist as a 12-month test channel, not a launch channel.**

Magist is a Brazilian online marketplace. Eniac, a European online retailer of premium tech, wanted to know whether Magist is the right partner to enter Brazil. I analysed two years of Magist orders in SQL to answer it.

The short version: the premium tech market on Magist is small, the customers mostly buy cheap accessories, and the delivery network is too slow for buyers who pay €1,000 for a laptop. But nobody owns the category yet. One focused seller could lead it within a year. That is worth testing, with clear rules for when to scale and when to walk away.

**[Interactive dashboard on Tableau Public]([TABLEAU_LINK](https://public.tableau.com/app/profile/samer.odeh/viz/Magistpremiumtechmarketentry/Dashboard1))**

![Dashboard](dashboard/dashboard.png)

---

## What the data says

### 1. The marketplace stopped growing
Orders grew fast through 2017 and peaked at **7,544 in November 2017** (Black Friday). In 2018 they went flat: **6,200 to 7,300 orders a month** from January to August. Eniac would join a marketplace that has stopped expanding, so any premium sales have to be won from a fixed customer base.

### 2. Premium tech is a niche inside a niche
Tech is **15.3% of items sold** and **14.0% of revenue**. Inside tech, the sales are low-ticket: computers_accessories, telephony and electronics make up **88%** of tech items. **Half of all tech items cost €50 or less**, and the average tech item (€110) is cheaper than the average item on Magist overall (€121).

Items above €500 are **3.3% of tech sales: 567 items in two years**. In 2018 the whole marketplace sold about **35 premium tech items a month, worth about €31,900**. Black Friday, the biggest traffic spike in the data, sold only 25. Promotions bring bargain hunters, not premium buyers.

### 3. Delivery is the deal breaker
Customers are promised **24.4 days** and receive their order in **12.5** on average. That gap makes the on-time rate look healthy (**93.2%**), but the rate is slipping, from 94.4% in 2017 to 92.3% in 2018.

Premium tech is the slowest parcel on the platform:

| Segment | Avg days to deliver | On time | Within 14 days |
|---|---|---|---|
| Premium tech | 15.5 | 91.5% | **61.1%** |
| Other tech | 13.0 | 93.2% | 68.3% |
| Non-tech | 12.4 | 93.2% | 71.8% |

Distance makes it worse. Customers in the North wait **22.5 days**, 2.6 times as long as São Paulo (8.7 days). Roraima is the slowest state at 29.3 days.

### 4. A late parcel costs you the review
On-time orders average **4.2 stars**. Late orders average **2.2**, and **64%** of late premium tech orders get 1 or 2 stars. For a new seller with no review history, a few late laptops would define the brand.

### 5. The opening: nobody owns premium tech
Only **91 sellers** sold a premium tech item, and **one seller made 27% of those sales**. The top three hold 40%. Demand also grew, from about 12 premium items a month in early 2017 to 35 in 2018. A seller with the right catalogue and reliable delivery could become the category leader quickly.

---

## Recommendation

Run Magist as a **12-month test**. Scale only if all three conditions are met at the end of it:

1. **A 14-day delivery promise that is kept.** Eniac promises delivery within 14 days and hits it on at least 9 of 10 orders. Today only 61% of premium tech orders arrive that fast. A fixed promise matters because Magist's own estimates are padded: in Amapá deliveries average 27 days, yet 97% count as "on time".
2. **Premium sales above today's whole market.** Over the year, Eniac alone sells more premium tech than the entire marketplace sells now: more than about 425 items or €383,000 (35 items and €31,900 a month). Anything less means Eniac only split an existing niche.
3. **Full access to current data.** This dataset ends in August 2018. Before any scale decision, Magist provides current order, delivery and review data for Eniac's listings and for the tech categories as a whole.

If any condition fails, Eniac keeps Magist as a minor channel and looks for a launch partner with faster logistics.

---

## How I worked

**Data:** the Magist database, a version of the public Olist Brazilian e-commerce dataset prepared by WBS Coding School. 99,441 orders, 9 tables, September 2016 to October 2018. September and October 2018 hold only 20 orders, so trends stop at August 2018.

**Tools:** MySQL 8 for the analysis, Tableau Public for the dashboard.

**Definitions**
- *Tech*: the 10 categories computers, computers_accessories, electronics, telephony, fixed_telephony, audio, consoles_games, pc_gamer, tablets_printing_image and cine_photo.
- *Premium tech*: a tech item priced above €500.
- *Prices* are per item, not per order.
- *On time*: delivered on or before the promised calendar date, `DATE(delivered) <= DATE(estimated)`. The promised date is stored at midnight, so a raw timestamp comparison would count a parcel delivered on the promised afternoon as late.
- *Delivery KPIs* use delivered orders only.

**Corrections to my first pass.** This started as a WBS Coding School case study. Rebuilding it for this portfolio, I fixed four things in my original queries:
- The on-time rate divided by all orders, including ones never delivered. That understated it at 89%. Delivered orders only gives 93.2%.
- Earlier figures mixed two on-time definitions (timestamp vs calendar date). All figures now use calendar dates.
- The "above average price" threshold was hard-coded at €120. It is now calculated.
- The minimum payment came out as €0 because of 9 voucher and undefined payments. These are excluded and flagged.

**Limitations**
- The data is eight to ten years old. That is the reason for condition 3.
- Olist prices are in Brazilian reais. The case study treats them as euros, and so does this analysis. Shares and ratios are unaffected; absolute amounts should be read as indicative.
- Reviews are linked to orders, not to individual items, so an order with one laptop and one cable shares one review.

---

## Repository

```
sql/
  01_market_entry.sql        the full analysis, one section per question, results in comments
  02_tableau_extracts.sql    the queries behind each CSV
data/                        CSV extracts used by the dashboard
dashboard/
  dashboard_spec.md          layout and chart design
  dashboard.png              screenshot
```

**Reproduce:** load the Magist dump into MySQL 8 (MariaDB works if you replace the collation `utf8mb4_0900_ai_ci` with `utf8mb4_general_ci`), then run `sql/01_market_entry.sql` top to bottom. It takes a few seconds.

---

*Samer Odeh, Berlin. [LinkedIn](LINKEDIN_LINK) · [Portfolio](https://samer-odeh.github.io)*

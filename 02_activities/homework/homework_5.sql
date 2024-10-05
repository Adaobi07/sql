-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */
-- First, let's create a subquery to multiply the number of products by the number of customers
WITH ProductCustomer AS (
    SELECT 
        v.vendor_name, 
        p.product_name, 
        p.price,
        COUNT(DISTINCT c.customer_id) * 5 AS total_units_sold
    FROM 
        vendor_inventory v
    CROSS JOIN 
        product p
    CROSS JOIN 
        customer c
    WHERE 
        v.product_id = p.product_id
    GROUP BY 
        v.vendor_id, p.product_id
)
SELECT 
    vendor_name, 
    product_name, 
    total_units_sold * price AS total_revenue
FROM 
    ProductCustomer;


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

-- Create the new table
CREATE TABLE product_units AS 
SELECT *, CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit';

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

-- Insert a new product (e.g., Apple Pie)
INSERT INTO product_units (product_name, product_size, product_qty_type, price, snapshot_timestamp)
VALUES ('Apple Pie', '1 pie', 'unit', 12.99, CURRENT_TIMESTAMP);

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/



-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

DELETE FROM product_units
WHERE product_name = 'Apple Pie'
AND snapshot_timestamp < (SELECT MAX(snapshot_timestamp) FROM product_units WHERE product_name = 'Apple Pie');

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

-- Add the new column
ALTER TABLE product_units
ADD current_quantity INT;

-- Update the current_quantity
UPDATE product_units
SET current_quantity = COALESCE((SELECT last_quantity FROM (
    SELECT 
        p.product_id, 
        vi.quantity AS last_quantity,
        ROW_NUMBER() OVER (PARTITION BY p.product_id ORDER BY vi.snapshot_timestamp DESC) as rn
    FROM 
        product_units p
    LEFT JOIN 
        vendor_inventory vi ON p.product_id = vi.product_id
    ) WHERE rn = 1
), 0)
WHERE product_id IN (SELECT product_id FROM product_units);



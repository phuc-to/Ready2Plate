USE mainproject;

-- 1

SELECT
  customer_fname,
  customer_lname,
  customer_email,
  customer_phone,
  address_id,
  customer_rewards 
FROM
  customer;

-- 2

SET
  @low_limit = 100;
SELECT
  i.ingredient_id,
  i.ingredient_name,
  k.ki_quantity,
  ingredient_unit 
FROM
  ingredient i 
  JOIN
    kitinventory k USING (ingredient_id) 
WHERE
  i.ingredient_unit = "pounds" 
  AND k.ki_quantity < @low_limit;

-- 3

SET @point_required = 40;
SET @fname = "gay";
SET @lname = "tourot";
SELECT
  customer_id,
  customer_fname,
  customer_lname,
  customer_rewards,
  (customer_rewards >= @point_required) AS eligibility 
FROM
  customer 
WHERE
  customer_fname = @fname AND customer_lname = @lname;

-- 4

SELECT
  k.kitentree_id,
  k.kitentree_name,
  k.kitentree_descript,
  COUNT(kl.kitentree_id) 
FROM
  kitentree k 
  JOIN
    kit_custorder_line kl USING (kitentree_id) 
GROUP BY
  kl.kitentree_id 
ORDER BY
  COUNT(kl.kitentree_id) DESC LIMIT 5;

-- 5

SELECT
  c.customer_id,
  c.customer_fname,
  c.customer_lname,
  c.customer_email,
  SUM(kcl.kcol_quantity*kcl.kcol_price) AS kitchenmoneyspent 
FROM
  customer c 
  JOIN
    kit_custorder kc 
    ON c.customer_id = kc.customer_id 
  JOIN
    kit_custorder_line kcl 
    ON kc.kco_id = kcl.kco_id 
GROUP BY
  c.customer_id 
ORDER BY
  kitchenmoneyspent DESC LIMIT 10;

SELECT
  c.customer_id,
  c.customer_fname,
  c.customer_lname,
  c.customer_email,
  SUM(bcl.bcol_quantity*bcl.bcol_price) AS barmoneyspent 
FROM
  customer c 
  JOIN
    bar_custorder bc 
    ON c.customer_id = bc.customer_id 
  JOIN
    bar_custorder_line bcl 
    ON bc.bco_id = bcl.bco_id 
GROUP BY
  c.customer_id 
ORDER BY
  barmoneyspent DESC LIMIT 10;

-- 6

SELECT
  bco_table AS bar_table,
  COUNT(bco_table) AS times_used 
FROM
  bar_custorder 
WHERE
  bco_date BETWEEN '2021-06-01' AND '2021-06-07' 
GROUP BY
  bco_table 
ORDER BY
  times_used DESC;

SELECT
  kco_table AS kitchen_table,
  COUNT(kco_table) AS times_used 
FROM
  kit_custorder 
WHERE
  kco_date BETWEEN '2021-06-01' AND '2021-06-07' 
GROUP BY
  kco_table 
ORDER BY
  times_used DESC;

-- 7

SELECT
  c.customer_id,
  c.customer_fname,
  c.customer_lname,
  c.customer_rewards,
  barentree_name,
  COUNT(bcol_quantity) AS times_ordered 
FROM
  ((bar_custorder AS bco 
    INNER JOIN
      bar_custorder_line AS bcol 
      ON bcol.bco_id = bco.bco_id) 
    INNER JOIN
      barentree AS be 
      ON be.barentree_id = bcol.barentree_id
  )
  INNER JOIN
    customer AS c 
    ON c.customer_id = bco.customer_id 
WHERE
  c.customer_rewards IS NOT NULL 
GROUP BY
  bcol.barentree_id 
ORDER BY
  times_ordered DESC;

SELECT
  c.customer_id,
  c.customer_fname,
  c.customer_lname,
  c.customer_rewards,
  kitentree_name,
  COUNT(kcol_quantity) AS times_ordered 
FROM
  ((kit_custorder AS kco 
    INNER JOIN
      kit_custorder_line AS kcol 
      ON kcol.kco_id = kco.kco_id) 
    INNER JOIN
      kitentree AS ke 
      ON ke.kitentree_id = kcol.kitentree_id)
  INNER JOIN
    customer AS c 
    ON c.customer_id = kco.customer_id 
WHERE
  c.customer_rewards IS NOT NULL 
GROUP BY
  kcol.kitentree_id 
ORDER BY
  times_ordered DESC;

-- 8

SELECT kitentree_name,
	ingredient_name AS missing_ingredient,
	kitrecipe_quantity AS units_per_recipe,
	IFNULL(ki_quantity, 0) AS units_on_hand,
	(kitrecipe_quantity - IFNULL(ki_quantity, 0)) AS missing_units 
FROM ((kitentree AS ke 
	INNER JOIN kitrecipe AS kr ON kr.kitentree_id = ke.kitentree_id) 
	INNER JOIN ingredient AS i ON i.ingredient_id = kr.ingredient_id)
	LEFT OUTER JOIN kitinventory AS ki ON ki.ingredient_id = i.ingredient_id 
WHERE kitrecipe_quantity - IFNULL(ki_quantity, 0) > 0
ORDER BY kitentree_name;

SELECT barentree_name,
	ingredient_name AS missing_ingredient,
	barrecipe_quantity AS units_per_recipe,
	IFNULL(bi_quantity, 0) AS units_on_hand,
	(barrecipe_quantity - IFNULL(bi_quantity, 0)) AS missing_units 
FROM ((barentree AS be 
	INNER JOIN barrecipe AS br ON br.barentree_id = be.barentree_id) 
	INNER JOIN ingredient AS i ON i.ingredient_id = br.ingredient_id)
	LEFT OUTER JOIN barinventory AS bi ON bi.ingredient_id = i.ingredient_id 
WHERE barrecipe_quantity - IFNULL(bi_quantity, 0) > 0
ORDER BY barentree_name;


-- 9

SELECT 
    total_of_kitchen_inventory_orders AS kitchen_order_expenses,
    total_of_bar_inventory_orders AS bar_order_expenses,
    total_of_kitchen_inventory_orders + total_of_bar_inventory_orders 
        AS inventory_order_expenses,
    total_of_kitchen_customer_orders AS kitchen_revenues,
    total_of_bar_customer_orders AS bar_revenues,
    total_of_kitchen_customer_orders + total_of_bar_customer_orders 
        AS customer_order_revenues,
    total_of_kitchen_customer_orders + total_of_bar_customer_orders
        - total_of_kitchen_inventory_orders - total_of_bar_inventory_orders 
        AS net_revenue
FROM(
    (SELECT 
        SUM(kit_order_cost) AS total_of_kitchen_inventory_orders
    FROM
        (SELECT SUM(kiol_price * kiol_quantity) AS kit_order_cost
        FROM kit_invorder AS ki
        INNER JOIN kit_invorder_line AS kil ON kil.kio_id = ki.kio_id
        WHERE kio_date BETWEEN '2021-06-01' AND '2021-06-07'
        GROUP BY ki.kio_id) AS kit_order_costs) AS kit_total_out, 
    (SELECT 
        SUM(bar_order_cost) AS total_of_bar_inventory_orders
    FROM 
        (SELECT SUM(biol_price * biol_quantity) AS bar_order_cost
        FROM bar_invorder AS bi
        INNER JOIN bar_invorder_line AS bil ON bil.bio_id = bi.bio_id
        WHERE bio_date BETWEEN '2021-06-01' AND '2021-06-07'
        GROUP BY bi.bio_id) AS bar_order_costs) AS bar_total_out, 
    (SELECT 
        SUM(kit_order_rev) AS total_of_kitchen_customer_orders
    FROM 
        (SELECT SUM(kcol_price * kcol_quantity) AS kit_order_rev
        FROM kit_custorder AS kc
        INNER JOIN kit_custorder_line AS kcl ON kcl.kco_id = kc.kco_id
        WHERE kco_date BETWEEN '2021-06-01' AND '2021-06-07'
        GROUP BY kc.kco_id) AS kit_order_revs) AS kit_total_in, 
    (SELECT 
        SUM(bar_order_rev) AS total_of_bar_customer_orders
    FROM 
        (SELECT SUM(bcol_price * bcol_quantity) AS bar_order_rev
        FROM bar_custorder AS bc
        INNER JOIN bar_custorder_line AS bcl ON bcl.bco_id = bc.bco_id
        WHERE bco_date BETWEEN '2021-06-01' AND '2021-06-07'
        GROUP BY bc.bco_id) AS bar_order_revs) AS bar_total_in);

-- 10

SELECT
  customer_fname,
  customer_lname,
  kc.kco_id,
  kco_date,
  SUM(kcol_quantity * kcol_price) AS order_total 
FROM
  (
    customer AS c 
    INNER JOIN
      kit_custorder AS kc 
      ON kc.customer_id = c.customer_id
  )
  INNER JOIN
    kit_custorder_line AS kcl 
    ON kcl.kco_id = kc.kco_id 
WHERE
  c.customer_id = 
  (
    SELECT
      customer_id 
    FROM
      customer 
    WHERE
      customer_fname = 'Selia' 
      AND customer_lname = 'Snalom'
  )
GROUP BY
  kc.kco_id 
ORDER BY
  kco_date DESC;

-- 11

Set @pattern = "% garlic %";
Select kitentree_name, kitentree_descript, kitentree_price
From (kitentree as ke
	Inner join kitrecipe as kr on kr.kitentree_id = kr.kitentree_id)
    Inner join ingredient as i on i.ingredient_id = kr.ingredient_id
Where kitentree_name Like @pattern
	Or kitentree_descript Like @pattern
    Or ingredient_name Like @pattern
    Or ingredient_descript Like @pattern
Order by kitentree_name;

-- 12

Select kitentree_name As entree, 
	kitentree_price As entree_price, 
	Sum(unit_price * kitrecipe_quantity) As entree_cost,
	kitentree_price - Sum(unit_price * kitrecipe_quantity) As margin
From ((kitentree as ke
	Left Outer Join kitrecipe as kr on kr.kitentree_id = ke.kitentree_id)
	Left Outer Join ingredient as i on i.ingredient_id = kr.ingredient_id)
	Left Outer Join (
		Select ingredient_id, Min(unit_price) As unit_price
		From supply as s
		Group by ingredient_id
		) as min_unit_prices on min_unit_prices.ingredient_id = i.ingredient_id
Group By ke.kitentree_id
Order By kitentree_price - Sum(unit_price * kitrecipe_quantity) Desc;

Select barentree_name As entree, 
	barentree_price As entree_price, 
	Sum(unit_price * barrecipe_quantity) As entree_cost,
	barentree_price - Sum(unit_price * barrecipe_quantity) As margin
From ((barentree as be
	Left Outer Join barrecipe as br on br.barentree_id = be.barentree_id)
	Left Outer Join ingredient as i on i.ingredient_id = br.ingredient_id)
	Left Outer Join (
		Select ingredient_id, Min(unit_price) As unit_price
		From supply as s
		Group by ingredient_id
		) as min_unit_prices on min_unit_prices.ingredient_id = i.ingredient_id
Group By be.barentree_id
Order By barentree_price - Sum(unit_price * barrecipe_quantity) Desc;

-- Stored Procedure
/*
Delimiter //

CREATE PROCEDURE `lookup_suppliers_for`(item VARCHAR(45)) 
BEGIN
  SELECT
    ingredient_name,
    ingredient_unit,
    supplier_name,
    unit_price,
    supplier_phone 
  FROM
    (
      ingredient AS i 
      INNER JOIN
        supply AS s 
        ON s.ingredient_id = i.ingredient_id
    )
    INNER JOIN
      supplier AS v 
      ON v.supplier_id = s.supplier_id 
  WHERE
    ingredient_name = item 
  ORDER BY
    unit_price;
END //

Delimiter ;*/

CALL lookup_suppliers_for("olive oil");
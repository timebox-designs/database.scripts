SET @month = 8;
SET @year = 2015;
SET @monthEnd = DATE_ADD(MAKEDATE(@year, 1), INTERVAL @month MONTH);
SET @30Days = SUBDATE(@monthEnd, INTERVAL 1 MONTH);


# Completed Orders

SELECT
  o.id 'Order No.'
  , DATE(o.ordereddate) 'Order Date'
  , DATE(t.dts) 'Completion Date'
  , s.descrip 'Order Status'
  , x.client_name 'Client Name'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , ot.descrip 'Product/Service'
  , IFNULL(a.vendor, '') 'Vendor A'
  , IFNULL(a.fee, 0) 'Fee A'
  , IFNULL(b.vendor, '') 'Vendor B'
  , IFNULL(b.fee, 0) 'Fee B'
  , IFNULL(c.vendor, '') 'Vendor C'
  , IFNULL(c.fee, 0) 'Fee C'
  , IFNULL(a.fee, 0) + IFNULL(b.fee, 0) + IFNULL(c.fee, 0) 'Total Fees'
  , t.amount 'Invoice Amount'
FROM
  (
    SELECT
      o.id
      , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'vendor'
      , SUM(p.vendorfee) 'fee'
    FROM orders o
      JOIN order_parts p ON o.id = p.orderid AND p.part_label = 'A'
      JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
      JOIN user_data_vendor v ON v.userid = p.acceptedby
    WHERE o.companyid = 2 # Axis
          AND o.order_status IN (7, 14) # Completed, Reconsideration
          AND p.order_status = 7 # Completed
          AND t.dts >= @30Days AND t.dts < @monthEnd
    GROUP BY o.id, p.acceptedby
  ) a
  LEFT JOIN
  (
    SELECT
      o.id
      , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'vendor'
      , SUM(p.vendorfee) 'fee'
    FROM orders o
      JOIN order_parts p ON o.id = p.orderid AND p.part_label = 'B'
      JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
      JOIN user_data_vendor v ON v.userid = p.acceptedby
    WHERE o.companyid = 2 # Axis
          AND o.order_status IN (7, 14) # Completed, Reconsideration
          AND p.order_status = 7 # Completed
          AND t.dts >= @30Days AND t.dts < @monthEnd
    GROUP BY o.id, p.acceptedby
  ) b ON b.id = a.id
  LEFT JOIN
  (
    SELECT
      o.id
      , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'vendor'
      , SUM(p.vendorfee) 'fee'
    FROM orders o
      JOIN order_parts p ON o.id = p.orderid AND p.part_label = 'C'
      JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
      JOIN user_data_vendor v ON v.userid = p.acceptedby
    WHERE o.companyid = 2 # Axis
          AND o.order_status IN (7, 14) # Completed, Reconsideration
          AND p.order_status = 7 # Completed
          AND t.dts >= @30Days AND t.dts < @monthEnd
    GROUP BY o.id, p.acceptedby
  ) c ON c.id = a.id
  JOIN orders o ON o.id = a.id
  JOIN order_types ot ON ot.id = o.order_type
  JOIN order_status s ON s.id = o.order_status
  JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
  JOIN clients x ON x.id = t.clientid
WHERE t.clientid <> 90  # Specialized Asset Management LLC
      AND ot.id NOT IN (17, 21) # 1004 Full URAR, 2055 Exterior-Only
ORDER BY x.client_name, t.dts;


# Accounts Payable (AP)

SELECT
  o.id 'Order No.'
  , DATE(t.dts) 'Completion Date'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , ot.descrip 'Product/Service'
  , p.vendorfee 'Vendor Fee'
  , p.acceptedby 'Vendor ID'
  , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'Vendor Name'
  , CASE WHEN ASCII(v.compname) = 194 THEN SUBSTR(v.compname, 2) # fuckery
    ELSE IFNULL(TRIM(v.compname), '') END 'Vendor Company'
  , CONCAT_WS(' ', v.tax_address, tax_city, tax_state, tax_zipcode) 'Vendor Address'
  , DATE(p.vendor_paid) 'Vendor Paid'
FROM orders o
  JOIN order_parts p ON o.id = p.orderid
  JOIN order_types ot ON ot.id = o.order_type
  JOIN part_types pt ON pt.id = p.part_type
  JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
  JOIN user_data_vendor v ON v.userid = p.acceptedby
WHERE o.companyid = 2 # Axis
      AND o.order_status IN (7, 14) # Completed, Reconsideration
      AND p.order_status = 7 # Completed
      AND ot.id NOT IN (17, 21) # 1004 Full URAR, 2055 Exterior-Only
      AND t.clientid <> 90 # Specialized Asset Management LLC
      AND t.dts >= @30Days AND t.dts < @monthEnd
ORDER BY 8, 2 # Vendor Company, Completion Date
;


# Accounts Receivable (AR)

SELECT
  s.id 'Statement No.'
  , s.statement_date 'Statement Date'
  , c.id 'Client No'
  , c.client_name 'Client Name'
  , o.borrowername 'Borrower Name'
  , o.id 'Order No.'
  , DATE(t.dts) 'Completion Date'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , ot.descrip 'Product/Service'
  , o.invoiceamount 'Invoice Amount'
FROM clients_statement AS s, client_transactions AS t
  JOIN orders AS o ON o.id = t.orderid
  JOIN order_types AS ot ON ot.id = o.order_type
  LEFT JOIN clients AS c ON c.id = t.clientid
WHERE FIND_IN_SET(t.id, s.transactions)
      AND o.companyid = 2 # Axis
      AND o.order_status IN (7, 14) # Completed, Reconsideration
      AND ot.id NOT IN (17, 21) # 1004 Full URAR, 2055 Exterior-Only
      AND t.type = 'COMPLETED'
      AND t.clientid <> 90 # Specialized Asset Management LLC
      AND t.dts >= @30Days AND t.dts < @monthEnd
ORDER BY s.id, t.dts;


# Accounts Receivable (YTD)

SELECT
  s.id 'Statement No.'
  , s.statement_date 'Statement Date'
  , c.id 'Client No'
  , c.client_name 'Client Name'
  , o.borrowername 'Borrower Name'
  , o.id 'Order No.'
  , DATE(t.dts) 'Completion Date'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , ot.descrip 'Product/Service'
  , o.invoiceamount 'Invoice Amount'
FROM clients_statement AS s, client_transactions AS t
  JOIN orders AS o ON o.id = t.orderid
  JOIN order_types AS ot ON ot.id = o.order_type
  LEFT JOIN clients AS c ON c.id = t.clientid
WHERE FIND_IN_SET(t.id, s.transactions)
      AND o.companyid = 2 # Axis
      AND o.order_status IN (7, 14) # Completed, Reconsideration
      AND ot.id NOT IN (17, 21) # 1004 Full URAR, 2055 Exterior-Only
      AND t.type = 'COMPLETED'
      AND t.clientid <> 90 # Specialized Asset Management LLC
      AND t.dts >= '2015-01-01 00:00:00'
ORDER BY s.id, t.dts;


# Supplemental ################################################################
# Completed orders

SELECT
  'With a transaction record' AS 'Completed Orders'
  , COUNT(*) 'Count'
FROM orders o
  LEFT JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
WHERE o.companyid = 2 # Axis
      AND o.order_status IN (7, 14) # Completed, Reconsideration
      AND t.orderid IS NOT NULL
UNION
SELECT
  'Without a transaction record'
  , COUNT(*)
FROM orders o
  LEFT JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
WHERE o.companyid = 2 # Axis
      AND o.order_status IN (7, 14) # Completed, Reconsideration
      AND t.orderid IS NULL;


# Completed orders by year, month

SELECT
  YEAR(t.dts) 'Year'
  , MONTHNAME(t.dts) 'Month'
  , COUNT(*) 'Orders'
FROM orders o
  JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
WHERE o.companyid = 2 # Axis
      AND o.order_status IN (7, 14) # Completed, Reconsideration
GROUP BY YEAR(t.dts), MONTH(t.dts);


# Completed client orders by product

SELECT
  c.client_name 'Client Name'
  , ot.descrip 'Product/Service'
  , COUNT(*) 'Orders'
  , SUM(t.amount) 'Invoiced'
FROM orders o
  JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
  JOIN order_types ot ON ot.id = o.order_type
  JOIN clients c ON c.id = t.clientid
WHERE o.companyid = 2 # Axis
      AND o.order_status IN (7, 14) # Completed, Reconsideration
      AND t.dts >= @30Days AND t.dts < @monthEnd
GROUP BY 1, 2
ORDER BY 2 DESC;


# Completed orders without a transaction record

SELECT
  c.id 'Client No'
  , c.client_name 'Client Name'
  , o.id 'Order No'
  , DATE(o.ordereddate) 'Order Date'
  , DATE(o.delivery_time) 'Delivery Date'
  , DATE(o.canceled_dts) 'Cancel Date'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , ot.descrip 'Product/Service'
  , o.invoiceamount 'Invoice Amount'
  , o.client_comments 'Client Comments'
FROM orders o
  JOIN order_types ot ON ot.id = o.order_type
  JOIN user_data_client u ON u.userid = o.orderbyid
  LEFT JOIN clients c ON c.id = u.clientid
  LEFT JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
WHERE o.companyid = 2 # Axis
      AND o.order_status IN (7, 14) # Completed, Reconsideration
      AND t.id IS NULL
ORDER BY o.ordereddate, o.delivery_time;



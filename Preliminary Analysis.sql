# Total Orders

SELECT COUNT(*) 'Orders'
FROM orders o
;

# Total Orders by Company (Note: company 0 does not exist, wtf?)

SELECT
  o.companyid 'Company ID'
  , COUNT(*) 'Orders'
FROM orders o
GROUP BY 1
;

# Axis Orders by Status

SELECT
  s.descrip 'Order Status'
  , COUNT(*) 'Total Orders'
FROM orders o
  JOIN order_status s ON s.id = o.order_status
WHERE o.companyid = 2 # Axis
GROUP BY 1
;

# Completed Axis Order Matrix

SELECT
  y.label AS 'Completed'
  , COALESCE(SUM(y.orders), 0) AS 'Orders'
  , COALESCE(SUM(y.test), 0) AS 'Test Orders'
  , COALESCE(SUM(y.total), 0) AS 'Total Orders'
FROM
  (
    SELECT
      x.label AS 'label'
      , CASE WHEN x.id = 0 THEN x.count END AS 'orders'
      , CASE WHEN x.id = 1 THEN x.count END AS 'test'
      , CASE WHEN x.id = 2 THEN x.count END AS 'total'
    FROM
      (
        SELECT
          'Invoiced' AS 'label'
          , 0 AS 'id'
          , COUNT(*) AS 'count'
        FROM clients_statement AS s, client_transactions AS t
          JOIN orders AS o ON o.id = t.orderid
          JOIN clients AS c ON c.id = t.clientid
        WHERE o.companyid = 2 # Axis
              AND t.type = 'COMPLETED'
              AND c.id NOT IN (1, 2, 283) # Test Clients
              AND FIND_IN_SET(t.id, s.transactions)

        UNION

        SELECT
          'Invoiced' AS 'label'
          , 1 AS 'id'
          , COUNT(*) AS 'count'
        FROM clients_statement AS s, client_transactions AS t
          JOIN orders AS o ON o.id = t.orderid
          JOIN clients AS c ON c.id = t.clientid
        WHERE o.companyid = 2 # Axis
              AND t.type = 'COMPLETED'
              AND c.id IN (1, 2, 283) # Test Clients
              AND FIND_IN_SET(t.id, s.transactions)

        UNION

        SELECT
          'Invoiced' AS 'label'
          , 2 AS 'id'
          , COUNT(*) AS 'count'
        FROM clients_statement AS s, client_transactions AS t
          JOIN orders AS o ON o.id = t.orderid
        WHERE o.companyid = 2 # Axis
              AND t.type = 'COMPLETED'
              AND FIND_IN_SET(t.id, s.transactions)

        UNION

        SELECT
          'Outstanding' AS 'label'
          , 0 AS 'id'
          , COUNT(*) AS 'count'
        FROM orders o
          JOIN client_transactions t ON t.orderid = o.id
          JOIN clients c ON c.id = t.clientid
          LEFT JOIN clients_statement s ON FIND_IN_SET(t.id, s.transactions)
        WHERE o.companyid = 2 # Axis
              AND t.type = 'COMPLETED'
              AND c.id NOT IN (1, 2, 283) # Test Clients
              AND s.id IS NULL

        UNION

        SELECT
          'Outstanding' AS 'label'
          , 1 AS 'id'
          , COUNT(*) AS 'count'
        FROM orders o
          JOIN client_transactions t ON t.orderid = o.id
          JOIN clients c ON c.id = t.clientid
          LEFT JOIN clients_statement s ON FIND_IN_SET(t.id, s.transactions)
        WHERE o.companyid = 2 # Axis
              AND t.type = 'COMPLETED'
              AND c.id IN (1, 2, 283) # Test Clients
              AND s.id IS NULL

        UNION

        SELECT
          'Outstanding' AS 'label'
          , 2 AS 'id'
          , COUNT(*) AS 'count'
        FROM orders o
          JOIN client_transactions t ON t.orderid = o.id
          LEFT JOIN clients_statement s ON FIND_IN_SET(t.id, s.transactions)
        WHERE o.companyid = 2 # Axis
              AND t.type = 'COMPLETED'
              AND s.id IS NULL

        UNION

        SELECT
          'Undefined' AS 'label'
          , 0 AS 'id'
          , COUNT(*) AS 'count'
        FROM orders o
          JOIN order_types p ON p.id = o.order_type
          JOIN user_data_client u ON u.userid = o.orderbyid
          JOIN clients c ON c.id = u.clientid
          LEFT JOIN client_transactions t ON t.orderid = o.id
        WHERE o.companyid = 2 # Axis
              AND o.order_status = 7
              AND c.id NOT IN (1, 2, 283) # Test Clients
              AND t.orderid IS NULL

        UNION

        SELECT
          'Undefined' AS 'label'
          , 1 AS 'id'
          , COUNT(*) AS 'count'
        FROM orders o
          JOIN order_types p ON p.id = o.order_type
          JOIN user_data_client u ON u.userid = o.orderbyid
          JOIN clients c ON c.id = u.clientid
          LEFT JOIN client_transactions t ON t.orderid = o.id
        WHERE o.companyid = 2 # Axis
              AND o.order_status = 7
              AND c.id IN (1, 2, 283) # Test Clients
              AND t.orderid IS NULL

        UNION

        SELECT
          'Undefined' AS 'label'
          , 2 AS 'id'
          , COUNT(*) AS 'count'
        FROM orders o
          JOIN order_types p ON p.id = o.order_type
          JOIN user_data_client u ON u.userid = o.orderbyid
          JOIN clients c ON c.id = u.clientid
          LEFT JOIN client_transactions t ON t.orderid = o.id
        WHERE o.companyid = 2 # Axis
              AND o.order_status = 7
              AND t.orderid IS NULL

      ) x
  ) y
GROUP BY 1
;

# Total Orders (Invoiced + Outstanding)

SELECT COUNT(*)
FROM orders o
  JOIN client_transactions t ON t.orderid = o.id
WHERE o.companyid = 2 # Axis
      AND t.type = 'COMPLETED'
;

# Undefined Orders (cross check)

SELECT COUNT(*)
FROM orders o
  LEFT JOIN client_transactions t ON t.orderid = o.id
WHERE o.companyid = 2 # Axis
      AND o.order_status = 7
      AND t.orderid IS NULL
;

# Invoiced Orders (these will appear on a client statement)

SELECT
  s.id 'Statement No.'
  , s.statement_date 'Statement Date'
  , c.client_name 'Client Name'
  , o.id 'Order No.'
  , DATE(o.ordereddate) 'Order Date'
  , DATE(t.dts) 'Delivery Date'
  , o.loanreference 'Ref. No.'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , p.descrip 'Product/Service'
  , o.invoiceamount 'Invoice Amount'
  , DATEDIFF(t.dts, o.ordereddate) 'Turn Time (Days)'
FROM clients_statement AS s, client_transactions AS t
  JOIN orders AS o ON o.id = t.orderid
  JOIN clients AS c ON c.id = t.clientid
  JOIN order_types AS p ON p.id = o.order_type
WHERE o.companyid = 2 # Axis
      AND t.type = 'COMPLETED'
      AND c.id NOT IN (1, 2, 283) # Test Clients
      AND FIND_IN_SET(t.id, s.transactions)
ORDER BY 2, 1, 6
;

# Outstanding Orders (these will be available next billing cycle)

SELECT
  c.client_name 'Client Name'
  , o.id 'Order No.'
  , DATE(o.ordereddate) 'Order Date'
  , DATE(t.dts) 'Delivery Date'
  , o.loanreference 'Ref. No.'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , p.descrip 'Product/Service'
  , o.invoiceamount 'Invoice Amount'
  , DATEDIFF(t.dts, o.ordereddate) 'Turn Time (Days)'
FROM orders o
  JOIN client_transactions t ON t.orderid = o.id
  JOIN clients c ON c.id = t.clientid
  JOIN order_types AS p ON p.id = o.order_type
  LEFT JOIN clients_statement s ON FIND_IN_SET(t.id, s.transactions)
WHERE o.companyid = 2 # Axis
      AND t.type = 'COMPLETED'
      AND c.id NOT IN (1, 2, 283) # Test Clients
      AND s.id IS NULL
ORDER BY 4, 2
;

# # Invoiced Test Orders
# 
# SELECT
#   s.id 'Statement No.'
#   , s.statement_date 'Statement Date'
#   , c.client_name 'Client Name'
#   , o.id 'Order No.'
#   , DATE(o.ordereddate) 'Order Date'
#   , DATE(t.dts) 'Delivery Date'
#   , o.loanreference 'Ref. No.'
#   , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
#   , p.descrip 'Product/Service'
#   , o.invoiceamount 'Invoice Amount'
#   , DATEDIFF(t.dts, o.ordereddate) 'Turn Time (Days)'
# FROM clients_statement AS s, client_transactions AS t
#   JOIN orders AS o ON o.id = t.orderid
#   JOIN order_types AS p ON p.id = o.order_type
#   JOIN clients AS c ON c.id = t.clientid
# WHERE o.companyid = 2 # Axis
#       AND t.type = 'COMPLETED'
#       AND c.id IN (1, 2, 283) # Test Clients
#       AND FIND_IN_SET(t.id, s.transactions)
# ;
# 
# # Outstanding Test Orders (mostly errors, not included in a month end)
# 
# SELECT
#   c.client_name 'Client Name'
#   , o.id 'Order No.'
#   , DATE(o.ordereddate) 'Order Date'
#   , DATE(t.dts) 'Delivery Date'
#   , o.loanreference 'Ref. No.'
#   , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
#   , p.descrip 'Product/Service'
#   , o.invoiceamount 'Invoice Amount'
#   , DATEDIFF(t.dts, o.ordereddate) 'Turn Time (Days)'
# FROM orders o
#   JOIN client_transactions t ON t.orderid = o.id
#   JOIN clients c ON c.id = t.clientid
#   JOIN order_types AS p ON p.id = o.order_type
#   LEFT JOIN clients_statement s ON FIND_IN_SET(t.id, s.transactions)
# WHERE o.companyid = 2 # Axis
#       AND t.type = 'COMPLETED'
#       AND c.id IN (1, 2, 283) # Test Clients
#       AND s.id IS NULL
# ORDER BY 4, 2
# ;

# Test Orders

SELECT
  c.client_name 'Client Name'
  , o.id 'Order No.'
  , DATE(o.ordereddate) 'Order Date'
  , DATE(t.dts) 'Delivery Date'
  , o.loanreference 'Ref. No.'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , p.descrip 'Product/Service'
  , o.invoiceamount 'Invoice Amount'
FROM clients_statement AS s, client_transactions AS t
  JOIN orders AS o ON o.id = t.orderid
  JOIN order_types AS p ON p.id = o.order_type
  JOIN clients AS c ON c.id = t.clientid
WHERE o.companyid = 2 # Axis
      AND t.type = 'COMPLETED'
      AND c.id IN (1, 2, 283) # Test Clients
      AND FIND_IN_SET(t.id, s.transactions)
UNION
SELECT
  c.client_name 'Client Name'
  , o.id 'Order No.'
  , DATE(o.ordereddate) 'Order Date'
  , DATE(t.dts) 'Delivery Date'
  , o.loanreference 'Ref. No.'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , p.descrip 'Product/Service'
  , o.invoiceamount 'Invoice Amount'
FROM orders o
  JOIN client_transactions t ON t.orderid = o.id
  JOIN clients c ON c.id = t.clientid
  JOIN order_types AS p ON p.id = o.order_type
  LEFT JOIN clients_statement s ON FIND_IN_SET(t.id, s.transactions)
WHERE o.companyid = 2 # Axis
      AND t.type = 'COMPLETED'
      AND c.id IN (1, 2, 283) # Test Clients
      AND s.id IS NULL
UNION
SELECT
  c.client_name 'Client Name'
  , o.id 'Order No.'
  , DATE(o.ordereddate) 'Order Date'
  , NULL 'Delivery Date'
  , o.loanreference 'Ref. No.'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , p.descrip 'Product/Service'
  , o.invoiceamount 'Invoice Amount'
FROM orders o
  JOIN order_types p ON p.id = o.order_type
  JOIN user_data_client u ON u.userid = o.orderbyid
  LEFT JOIN clients c ON c.id = u.clientid
  LEFT JOIN client_transactions t ON t.orderid = o.id
WHERE o.companyid = 2 # Axis
      AND o.order_status = 7 # Completed
      AND c.id IN (1, 2, 283) # Test Clients
      AND t.orderid IS NULL
ORDER BY 2
;

# Undefined Orders 

SELECT
  c.client_name 'Client Name'
  , o.id 'Order No.'
  , DATE(o.ordereddate) 'Order Date'
  , o.loanreference 'Ref. No.'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , p.descrip 'Product/Service'
  , o.invoiceamount 'Invoice Amount'
FROM orders o
  JOIN order_types p ON p.id = o.order_type
  JOIN user_data_client u ON u.userid = o.orderbyid
  LEFT JOIN clients c ON c.id = u.clientid
  LEFT JOIN client_transactions t ON t.orderid = o.id
WHERE o.companyid = 2 # Axis
      AND o.order_status = 7 # Completed
      AND c.id NOT IN (1, 2, 283) # Test Clients
      AND t.orderid IS NULL
ORDER BY 2
;

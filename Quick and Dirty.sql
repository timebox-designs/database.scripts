SET @startDate = '2015-08-01 00:00:00';
SET @endDate = '2015-09-01 00:00:00';

# Clients who ordered in 2014 - 2015

# SELECT
#   c.id 'Client No'
#   , c.client_name 'Client Name'
#   , b.bill_name 'Billing Name'
#   , CONCAT_WS(' ', b.bill_address1, b.bill_address2, b.bill_city, b.bill_state, b.bill_zipcode) 'Billing Address'
#   , DATE(x.date) 'Last Order Placed'
#   , DATE(c.date_added) 'Date Added'
#   , CONCAT_WS(' ', d.firstname, d.lastname) 'Contact'
#   , u.id 'Contact ID'
#   , u.email 'Contact Email'
#   , c.phone 'Company Phone'
#   , DATE(u.register_date) 'Contact Register Date'
# FROM
#   (
#     SELECT
#       t.clientid
#       , MAX(o.ordereddate) 'date'
#     FROM orders o
#       JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
#     WHERE o.companyid = 1
#           AND o.order_status = 7
#           AND t.dts >= @startDate AND t.dts < @endDate
#     GROUP BY 1
#   ) x
#   JOIN clients c ON c.id = x.clientid
#   JOIN clients_accounting_pref b ON b.clientid = c.id
#   JOIN user_data_client d ON d.clientid = c.id
#   JOIN user u ON u.id = d.userid AND u.active = 'Y' AND u.user_type = 3 # Client
# ORDER BY x.date, c.client_name, u.register_date;

SELECT
  c.client_name 'Client'
  , ot.descrip 'Product/Service'
  , s.descrip 'Status'
  , DATE(o.ordereddate) 'Date'
  , COUNT(*) 'Orders'
FROM orders o
  JOIN order_status s ON s.id = o.order_status
  JOIN order_types ot ON ot.id = o.order_type
  JOIN user_data_client u ON u.userid = o.orderbyid
  JOIN clients c ON c.id = u.clientid
WHERE o.companyid = 1
      AND o.ordereddate >= @startDate AND o.ordereddate < @endDate
GROUP BY 1, 2, 3, 4;

SELECT
  o.ordereddate
  , p.accepteddate
  , ot.descrip
  , p.part_label
  , pt.descrip
  , CASE WHEN p.accepteddate = '0000-00-00 00:00:00' THEN NULL
    ELSE ROUND(TIME_TO_SEC(TIMEDIFF(p.accepteddate, o.ordereddate)) / 3600, 2) END 'Placement Delay (Hours)'
  , o.order_status
FROM orders o
  LEFT JOIN order_parts p ON p.orderid = o.id
  LEFT JOIN order_types ot ON ot.id = o.order_type
  LEFT JOIN part_types pt ON pt.id = p.part_type AND pt.id NOT IN (2, 3, 4)
WHERE o.companyid = 1
      AND o.ordereddate >= @startDate AND o.ordereddate < @endDate;

SELECT
  ot.descrip 'Product/Service'
  , s.descrip 'Status'
  , COUNT(*) 'Orders'
FROM orders o
  JOIN order_parts p ON p.orderid = o.id AND p.part_type NOT IN (2, 3, 4)
  JOIN order_status s ON s.id = o.order_status
  JOIN order_types ot ON ot.id = o.order_type
WHERE o.companyid = 1
      AND o.ordereddate >= @startDate AND o.ordereddate < @endDate
GROUP BY 1, 2;


SELECT
  o.id 'Order No'
  , ot.descrip 'Product/Service'
  , s.descrip 'Status'
  , o.ordereddate 'Order Date'
  , p.accepteddate 'Accepted Date'
  , ROUND(TIME_TO_SEC(TIMEDIFF(p.accepteddate, o.ordereddate)) / 3600, 2) 'Placement Delay (Hours)'
  , p.part_label 'Label'
  , p.acceptedby 'Vendor No'
  , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'Vendor Name'
  , p.vendorfee 'Vendor Fee'
FROM orders o
  JOIN order_parts p ON p.orderid = o.id AND p.part_type NOT IN (2, 3, 4)
  JOIN order_status s ON s.id = o.order_status
  JOIN order_types ot ON ot.id = o.order_type
  JOIN user_data_vendor v ON v.userid = p.acceptedby
WHERE o.companyid = 1
      AND o.ordereddate >= @endDate
ORDER BY o.id, p.part_label;


SELECT
  o.id
  , ot.descrip 'Product/Service'
  , s.descrip 'Status'
  , o.ordereddate 'Order Date'
  , p.accepteddate 'Accepted Date'
  , ROUND(TIME_TO_SEC(TIMEDIFF(p.accepteddate, o.ordereddate)) / 3600, 2) 'Placement Delay (Hours)'
  , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'vendor'
  , p.vendorfee 'fee'
FROM orders o
  JOIN order_parts p ON o.id = p.orderid AND p.part_label = 'A'
  JOIN order_status s ON s.id = o.order_status
  JOIN order_types ot ON ot.id = o.order_type
  JOIN user_data_vendor v ON v.userid = p.acceptedby
WHERE o.companyid = 1
      AND ot.id <> 45 # Trip Fee
      AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
      AND o.ordereddate >= @endDate;

SELECT
  o.id 'Order No'
  , ot.descrip 'Product'
  , o.ordereddate 'Order Date'
  , p.accepteddate 'Accepted Date'
  , CASE WHEN p.accepteddate = '0000-00-00 00:00:00' THEN ROUND(TIME_TO_SEC(TIMEDIFF(NOW(), o.ordereddate)) / 3600, 2)
    ELSE ROUND(TIME_TO_SEC(TIMEDIFF(p.accepteddate, o.ordereddate)) / 3600, 2) END 'Placement Delay (Hours)'
  , CASE WHEN p.accepteddate = '0000-00-00 00:00:00' THEN ROUND(TIME_TO_SEC(TIMEDIFF(NOW(), o.ordereddate)) / 86400, 2)
    ELSE ROUND(TIME_TO_SEC(TIMEDIFF(p.accepteddate, o.ordereddate)) / 86400, 2) END 'Placement Delay (Days)'
FROM orders o
  JOIN order_parts p ON o.id = p.orderid AND p.part_label = 'A'
  JOIN order_types ot ON ot.id = o.order_type
WHERE o.companyid = 1
      AND o.order_type <> 45 # Trip Fee
      AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
      AND o.ordereddate >= @endDate
ORDER BY p.accepteddate DESC;

# SET time_zone='US/Pacific';

SET @now = CONVERT_TZ(NOW(), 'UTC', 'US/Pacific');
SELECT @now;

SELECT
  c.client_name 'Client Name'
  , o.id 'Order No'
  , s.descrip 'Status'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , ot.descrip 'Product'
  , o.ordereddate 'Order Date'
  , @now 'US/Pacific Time (Now)'
  , ROUND(TIME_TO_SEC(TIMEDIFF(@now, o.ordereddate)) / 3600, 2) 'Placement Delay (Hours)'
  , ROUND(TIME_TO_SEC(TIMEDIFF(@now, o.ordereddate)) / 86400, 2) 'Placement Delay (Days)'
FROM orders o
  JOIN order_parts p ON o.id = p.orderid AND p.part_label = 'A'
  JOIN order_types ot ON ot.id = o.order_type
  JOIN order_status s ON s.id = o.order_status
  JOIN user_data_client u ON u.userid = o.orderbyid
  JOIN clients c ON c.id = u.clientid
WHERE o.companyid = 1
      AND ot.id <> 45 # Trip Fee
      AND s.id NOT IN (10, 12) # Order Canceled
      AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
      AND p.accepteddate = '0000-00-00 00:00:00'
      AND o.ordereddate >= '2015-01-01 00:00:00'
ORDER BY o.ordereddate, o.id;

SELECT
  o.id 'Order No'
  , DATE(o.ordereddate) 'Order Date'
  , x.client_name 'Client Name'
  , s.descrip 'Order Status'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , ot.descrip 'Product'
  , IFNULL(a.status, '') 'Part A'
  , a.accepteddate
  , IFNULL(a.delay, '') 'Acceptance Delay (hours)'
  , IFNULL(ROUND(a.delay / 24, 2), '') 'Delay (days)'
  , IFNULL(b.status, '') 'Part B'
  , IFNULL(b.delay, '') 'Acceptance Delay (hours)'
  , IFNULL(ROUND(b.delay / 24, 2), '') 'Delay (days)'
  , IFNULL(c.status, '') 'Part C'
  , IFNULL(c.delay, '') 'Acceptance Delay (hours)'
  , IFNULL(ROUND(b.delay / 24, 2), '') 'Delay (days)'
FROM orders o
  JOIN order_types ot ON ot.id = o.order_type
  JOIN order_status s ON s.id = o.order_status # Completed, Canceled, Duplicate
                         AND s.id NOT IN (7, 10, 12)
  JOIN user_data_client u ON u.userid = o.orderbyid
  JOIN clients x ON x.id = u.clientid
  LEFT JOIN
  (
    SELECT
      o.id
      , p.accepteddate
      , s.descrip 'status'
      , ROUND(TIME_TO_SEC(TIMEDIFF(p.accepteddate, o.ordereddate)) / 3600, 2) 'delay'
    FROM orders o
      JOIN order_parts p ON o.id = p.orderid
                            AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
                            AND p.part_label = 'A'
      JOIN order_status s ON s.id = p.order_status
    WHERE o.companyid = 1
          AND o.ordereddate >= '2015-01-01 00:00:00'
  ) a ON a.id = o.id
  LEFT JOIN
  (
    SELECT
      o.id
      , s.descrip 'status'
      , ROUND(TIME_TO_SEC(TIMEDIFF(p.accepteddate, o.ordereddate)) / 3600, 2) 'delay'
    FROM orders o
      JOIN order_parts p ON o.id = p.orderid
                            AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
                            AND p.part_label = 'B'
      JOIN order_status s ON s.id = p.order_status
    WHERE o.companyid = 1
          AND o.ordereddate >= '2015-01-01 00:00:00'
  ) b ON b.id = a.id
  LEFT JOIN
  (
    SELECT
      o.id
      , s.descrip 'status'
      , ROUND(TIME_TO_SEC(TIMEDIFF(p.accepteddate, o.ordereddate)) / 3600, 2) 'delay'
    FROM orders o
      JOIN order_parts p ON o.id = p.orderid
                            AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
                            AND p.part_label = 'C'
      JOIN order_status s ON s.id = p.order_status
    WHERE o.companyid = 1
          AND o.ordereddate >= '2015-01-01 00:00:00'
  ) c ON c.id = a.id
WHERE o.companyid = 1
      AND o.ordereddate >= '2015-01-01 00:00:00'
ORDER BY o.order_status, o.ordereddate;

SELECT
  o.id 'Order No'
  #   , DATE(o.ordereddate) 'Order Date'
  #   , x.client_name 'Client Name'
  , s.descrip 'Order Status'
  #   , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , ot.descrip 'Product'
  , IFNULL(a.status, '') 'Part A'
  , IFNULL(b.status, '') 'Part B'
  , IFNULL(c.status, '') 'Part C'
FROM orders o
  JOIN order_types ot ON ot.id = o.order_type
  JOIN order_status s ON s.id = o.order_status # Completed, Canceled, Reconsideration
                         AND s.id IN (7, 10, 14)
  JOIN user_data_client u ON u.userid = o.orderbyid
  JOIN clients x ON x.id = u.clientid
  LEFT JOIN
  (
    SELECT
      o.id
      , p.accepteddate
      , s.descrip 'status'
      , ROUND(TIME_TO_SEC(TIMEDIFF(p.accepteddate, o.ordereddate)) / 3600, 2) 'delay'
    FROM orders o
      JOIN order_parts p ON o.id = p.orderid
                            AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
                            AND p.part_label = 'A'
      JOIN order_status s ON s.id = p.order_status
    WHERE o.companyid = 1
          AND o.ordereddate >= '2015-01-01 00:00:00'
  ) a ON a.id = o.id
  LEFT JOIN
  (
    SELECT
      o.id
      , s.descrip 'status'
      , ROUND(TIME_TO_SEC(TIMEDIFF(p.accepteddate, o.ordereddate)) / 3600, 2) 'delay'
    FROM orders o
      JOIN order_parts p ON o.id = p.orderid
                            AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
                            AND p.part_label = 'B'
      JOIN order_status s ON s.id = p.order_status
    WHERE o.companyid = 1
          AND o.ordereddate >= '2015-01-01 00:00:00'
  ) b ON b.id = a.id
  LEFT JOIN
  (
    SELECT
      o.id
      , s.descrip 'status'
      , ROUND(TIME_TO_SEC(TIMEDIFF(p.accepteddate, o.ordereddate)) / 3600, 2) 'delay'
    FROM orders o
      JOIN order_parts p ON o.id = p.orderid
                            AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
                            AND p.part_label = 'C'
      JOIN order_status s ON s.id = p.order_status
    WHERE o.companyid = 1
          AND o.ordereddate >= '2015-01-01 00:00:00'
  ) c ON c.id = a.id
WHERE o.companyid = 1
      AND o.ordereddate >= '2015-01-01 00:00:00'
ORDER BY o.order_status, o.ordereddate;


SELECT *
FROM order_parts p
WHERE p.orderid = 140912;

SELECT *
FROM part_types;

SELECT
  o.id
  , ot.descrip 'Product'
  , s.descrip 'Status'
  , o.ordereddate
  , a.accepteddate
  , b.accepteddate
  , c.accepteddate
FROM orders o
  JOIN order_status s ON s.id = o.order_status
  JOIN order_types ot ON ot.id = o.order_type
  LEFT JOIN order_parts a ON a.orderid = o.id AND a.part_label = 'A' AND a.part_type NOT IN (2, 3, 4)
  LEFT JOIN order_parts b ON b.orderid = o.id AND b.part_label = 'B' AND b.part_type NOT IN (2, 3, 4)
  LEFT JOIN order_parts c ON c.orderid = o.id AND c.part_label = 'C' AND c.part_type NOT IN (2, 3, 4)
WHERE o.companyid = 1
      AND o.order_status NOT IN (7, 10, 12)
      AND o.ordereddate >= '2015-01-01 00:00:00'
ORDER BY o.ordereddate;


SELECT
  o.id 'Order No'
  , ot.descrip 'Product'
  , s.descrip 'Order Status'
  , a.status
FROM orders o
  JOIN order_types ot ON ot.id = o.order_type
  JOIN order_status s ON s.id = o.order_status
  LEFT JOIN
  (
    SELECT
      o.id
      , s.descrip 'status'
    FROM orders o
      JOIN order_parts p ON p.orderid = o.id
      JOIN order_status s ON s.id = p.order_status
    WHERE o.companyid = 1
          AND p.part_label = 'A'
          AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
          AND o.ordereddate >= '2015-09-01 00:00:00'
  ) a ON a.id = o.id
WHERE o.companyid = 1
      AND o.ordereddate >= '2015-09-01 00:00:00';


SELECT
  s.id 'Status ID'
  , s.descrip 'Status'
  , COUNT(*) 'Orders'
FROM orders o
  JOIN order_status s ON s.id = o.order_status
WHERE o.companyid = 1
      AND o.ordereddate >= '2015-09-01 00:00:00'
GROUP BY 1, 2;

# SELECT
#   s.descrip
#   , sa.descrip
#   , sb.descrip
#   , sc.descrip
#   , COUNT(*)
# FROM orders o
#   JOIN order_status s ON s.id = o.order_status
#   LEFT JOIN order_parts pa ON o.id = pa.orderid AND pa.part_label = 'A'
#   JOIN order_status sa ON sa.id = pa.order_status
#   LEFT JOIN order_parts pb ON o.id = pb.orderid AND pb.part_label = 'B'
#   JOIN order_status sb ON sb.id = pb.order_status
#   LEFT JOIN order_parts pc ON o.id = pc.orderid AND pc.part_label = 'C'
#   JOIN order_status sc ON sc.id = pc.order_status
# WHERE o.companyid = 1
#       AND o.ordereddate >= '2015-09-01 00:00:00'
# GROUP BY 1, 2, 3, 4;

SET time_zone = 'US/Pacific';
SET @startDate = '2015-01-01 00:00:00';

SELECT
  NOW() 'Timestamp'
  , o.id 'Order No'
  , DATE(o.ordereddate) 'Order Date'
  , x.client_name 'Client Name'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , ot.descrip 'Product'
  , s.descrip 'Order Status'
  , IFNULL(a.part_status, '') 'Part A'
  , a.accepteddate 'Accepted Date'
  , a.start_dts 'Start Date'
  , IFNULL(ROUND(a.delay / 86400, 2), '') 'Start Delay (days)'
  , IFNULL(ROUND(a.delta / 86400, 2), '') 'Vendor Delay (days)'
  , IFNULL(b.part_status, '') 'Part B'
  , b.accepteddate 'Accepted Date'
  , b.start_dts 'Start Date'
  , IFNULL(ROUND(b.delay / 86400, 2), '') 'Start Delay (days)'
  , IFNULL(ROUND(b.delta / 86400, 2), '') 'Vendor Delay (days)'
  , IFNULL(c.part_status, '') 'Part C'
  , c.accepteddate 'Accepted Date'
  , c.start_dts 'Start Date'
  , IFNULL(ROUND(c.delay / 86400, 2), '') 'Start Delay (days)'
  , IFNULL(ROUND(c.delta / 86400, 2), '') 'Vendor Delay (days)'
FROM orders o
  JOIN order_types ot ON ot.id = o.order_type
  JOIN order_status s ON s.id = o.order_status
  JOIN user_data_client u ON u.userid = o.orderbyid
  JOIN clients x ON x.id = u.clientid
  JOIN
  (
    SELECT
      o.id
      , s.descrip 'part_status'
      , IF(p.start_dts = '0000-00-00 00:00:00', (UNIX_TIMESTAMP() - UNIX_TIMESTAMP(o.ordereddate)),
           (UNIX_TIMESTAMP(p.start_dts) - UNIX_TIMESTAMP(o.ordereddate))) 'delay'
      , IF(p.start_dts = '0000-00-00 00:00:00', 0,
           (UNIX_TIMESTAMP(p.start_dts) - UNIX_TIMESTAMP(p.accepteddate))) 'delta'
      , p.start_dts
      , p.accepteddate
    FROM orders o
      JOIN order_parts p ON o.id = p.orderid AND p.part_label = 'A'
      JOIN order_status s ON s.id = p.order_status
    WHERE o.companyid = 1
          AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
          AND o.ordereddate >= @startDate
  ) a ON a.id = o.id
  LEFT JOIN
  (
    SELECT
      o.id
      , s.descrip 'part_status'
      , IF(p.start_dts = '0000-00-00 00:00:00', (UNIX_TIMESTAMP() - UNIX_TIMESTAMP(o.ordereddate)),
           (UNIX_TIMESTAMP(p.start_dts) - UNIX_TIMESTAMP(o.ordereddate))) 'delay'
      , IF(p.start_dts = '0000-00-00 00:00:00', 0,
           (UNIX_TIMESTAMP(p.start_dts) - UNIX_TIMESTAMP(p.accepteddate))) 'delta'
      , p.start_dts
      , p.accepteddate
    FROM orders o
      JOIN order_parts p ON o.id = p.orderid AND p.part_label = 'B'
      JOIN order_status s ON s.id = p.order_status
    WHERE o.companyid = 1
          AND p.part_type NOT IN (2, 3) # Exterior, Interior
          AND o.ordereddate >= @startDate
  ) b ON b.id = o.id
  LEFT JOIN
  (
    SELECT
      o.id
      , s.descrip 'part_status'
      , IF(p.start_dts = '0000-00-00 00:00:00', (UNIX_TIMESTAMP() - UNIX_TIMESTAMP(o.ordereddate)),
           (UNIX_TIMESTAMP(p.start_dts) - UNIX_TIMESTAMP(o.ordereddate))) 'delay'
      , IF(p.start_dts = '0000-00-00 00:00:00', 0,
           (UNIX_TIMESTAMP(p.start_dts) - UNIX_TIMESTAMP(p.accepteddate))) 'delta'
      , p.start_dts
      , p.accepteddate
    FROM orders o
      JOIN order_parts p ON o.id = p.orderid AND p.part_label = 'C'
      JOIN order_status s ON s.id = p.order_status
    WHERE o.companyid = 1
          AND p.part_type NOT IN (2, 3) # Exterior, Interior
          AND o.ordereddate >= @startDate
  ) c ON c.id = o.id
WHERE o.companyid = 1
      AND o.order_status NOT IN (7, 10, 12) # Completed, Canceled, Duplicate
      AND o.order_type <> 45 # Trip Fee
      AND o.ordereddate >= @startDate
ORDER BY o.order_status, o.ordereddate;


# Internal Delays (The order part has not been placed with a vendor)

SELECT
  NOW() 'Timestamp'
  , o.id 'Order No'
  , o.ordereddate 'Order Date'
  , c.client_name 'Client Name'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , ot.descrip 'Product'
  , os.descrip 'Order Status'
  , ps.descrip 'Part Status'
  , p.part_label 'Label'
  , IFNULL(ROUND((UNIX_TIMESTAMP() - UNIX_TIMESTAMP(o.ordereddate)) / 86400, 2), '') 'Acceptance Delay (days)'
FROM orders o
  JOIN order_parts p ON o.id = p.orderid
  JOIN order_types ot ON ot.id = o.order_type
  JOIN order_status os ON os.id = o.order_status
  JOIN order_status ps ON ps.id = p.order_status
  JOIN user_data_client u ON u.userid = o.orderbyid
  JOIN clients c ON c.id = u.clientid
WHERE o.companyid = 1
      AND o.order_status NOT IN (7, 10, 12) # Completed, Canceled, Duplicate
      AND p.order_status <> 10 # Canceled
      AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
      AND p.accepteddate = '0000-00-00 00:00:00'
      AND o.ordereddate >= @startDate
ORDER BY o.ordereddate, p.part_label;


# External Delays (The vendor has not started)

SELECT
  NOW() 'Timestamp'
  , o.id 'Order No'
  , o.ordereddate 'Order Date'
  , c.client_name 'Client Name'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , ot.descrip 'Product'
  , os.descrip 'Order Status'
  , ps.descrip 'Part Status'
  , p.part_label 'Label'
  , IFNULL(
        ROUND((UNIX_TIMESTAMP(p.accepteddate) - UNIX_TIMESTAMP(o.ordereddate)) / 86400, 2),
        '') 'Acceptance Delay (days)'
  , IFNULL(ROUND((UNIX_TIMESTAMP() - UNIX_TIMESTAMP(o.ordereddate)) / 86400, 2), '') 'Start Delay (days)'
  , p.acceptedby 'Vendor No'
  , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'Vendor Name'
FROM orders o
  JOIN order_parts p ON p.orderid = o.id
  JOIN order_types ot ON ot.id = o.order_type
  JOIN order_status os ON os.id = o.order_status
  JOIN order_status ps ON ps.id = p.order_status
  JOIN user_data_vendor v ON v.userid = p.acceptedby
  JOIN user_data_client u ON u.userid = o.orderbyid
  JOIN clients c ON c.id = u.clientid
WHERE o.companyid = 1
      AND o.order_status NOT IN (7, 10, 12) # Completed, Canceled, Duplicate
      AND p.order_status <> 10 # Canceled
      AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
      AND p.accepteddate > '0000-00-00 00:00:00'
      AND p.start_dts = '0000-00-00 00:00:00'
      AND o.ordereddate >= @startDate
ORDER BY o.ordereddate, p.part_label;


# External Delays (The order has been started, but has not yet completed)

SELECT
  NOW() 'Timestamp'
  , o.id 'Order No'
  , o.ordereddate 'Order Date'
  , c.client_name 'Client Name'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , ot.descrip 'Product'
  , os.descrip 'Order Status'
  , ps.descrip 'Part Status'
  , p.part_label 'Label'
  , IFNULL(
        ROUND((UNIX_TIMESTAMP(p.accepteddate) - UNIX_TIMESTAMP(o.ordereddate)) / 86400, 2),
        '') 'Acceptance Delay (days)'
  , IFNULL(ROUND((UNIX_TIMESTAMP(p.start_dts) - UNIX_TIMESTAMP(p.accepteddate)) / 86400, 2), '') 'Start Delay (days)'
  , IFNULL(ROUND((UNIX_TIMESTAMP() - UNIX_TIMESTAMP(o.ordereddate)) / 86400, 2), '') 'Full Delay (days)'
  , p.acceptedby 'Vendor No'
  , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'Vendor Name'
FROM orders o
  JOIN order_parts p ON p.orderid = o.id
  JOIN order_types ot ON ot.id = o.order_type
  JOIN order_status os ON os.id = o.order_status
  JOIN order_status ps ON ps.id = p.order_status
  JOIN user_data_vendor v ON v.userid = p.acceptedby
  JOIN user_data_client u ON u.userid = o.orderbyid
  JOIN clients c ON c.id = u.clientid
WHERE o.companyid = 1
      AND o.order_status NOT IN (7, 10, 12) # Completed, Canceled, Duplicate
      AND p.order_status <> 10 # Canceled
      AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
      AND p.start_dts > '0000-00-00 00:00:00'
      AND o.ordereddate >= @startDate
ORDER BY o.ordereddate, p.part_label;

# 149142

# CREATE TEMPORARY TABLE a AS
SELECT
  a.id
  , a.part_label
  , a.start_dts
  , b.inspection_dts
FROM
  (
    SELECT
      o.id
      , p.part_label
      , p.start_dts
    FROM orders o
      JOIN order_parts p ON o.id = p.orderid AND p.part_label = 'A' AND p.part_type NOT IN (2, 3) # Exterior, Interior
    WHERE o.companyid = 1
          AND o.order_status NOT IN (7, 10, 12) # Completed, Canceled, Duplicate
          AND p.order_status <> 10 # Canceled
          AND p.accepteddate > '0000-00-00 00:00:00'
          AND o.ordereddate >= @startDate
  ) a
  LEFT JOIN
  (
    SELECT
      o.id
      , p.inspection_dts
    FROM orders o
      JOIN order_parts p ON o.id = p.orderid AND p.part_label = 'A' AND p.part_type IN (2, 3) # Exterior, Interior
    WHERE o.companyid = 1
          AND o.order_status NOT IN (7, 10, 12) # Completed, Canceled, Duplicate
          AND p.order_status <> 10 # Canceled
          AND p.accepteddate > '0000-00-00 00:00:00'
          AND o.ordereddate >= @startDate
  ) b ON b.id = a.id;


SELECT
  x.id
  , x.part_label
  , x.start_dts
  , y.inspection_dts
FROM orders o
  LEFT JOIN order_parts x ON x.orderid = o.id
                             AND x.part_label = 'A'
                             AND x.part_type NOT IN (2, 3, 4) # Exterior, Interior
                             AND x.order_status <> 10
                             AND x.accepteddate > '0000-00-00 00:00:00'
  LEFT JOIN order_parts y ON y.orderid = o.id
                             AND y.part_label = 'A'
                             AND y.part_type IN (2, 3) # Exterior, Interior
                             AND y.order_status <> 10
                             AND y.accepteddate > '0000-00-00 00:00:00'
WHERE o.companyid = 1
      AND o.order_status NOT IN (7, 10, 12) # Completed, Canceled, Duplicate
      AND o.ordereddate >= @startDate;


# DROP TEMPORARY TABLE IF EXISTS a;


SELECT
  part_type
  , COUNT(*)
FROM orders o
  JOIN order_parts p ON o.id = p.orderid AND p.part_label = 'A'
WHERE o.companyid = 1
      AND o.order_status NOT IN (7, 10, 12) # Completed, Canceled, Duplicate
      AND p.order_status <> 10 # Canceled
      AND p.accepteddate > '0000-00-00 00:00:00'
      AND o.ordereddate >= @startDate
GROUP BY 1;

SELECT
  s.descrip
  , COUNT(*)
FROM orders o
  JOIN order_parts p ON p.orderid = o.id
  JOIN order_status s ON s.id = p.order_status
WHERE o.companyid = 1
      AND o.order_status NOT IN (7, 10, 12) # Completed, Canceled, Duplicate
      AND p.accepteddate = '0000-00-00 00:00:00'
      AND o.ordereddate >= @startDate
GROUP BY 1;

SELECT
  s.descrip
  , COUNT(*)
FROM orders o
  JOIN order_parts p ON p.orderid = o.id
  JOIN order_status s ON s.id = o.order_status
WHERE o.companyid = 1
      AND p.order_status NOT IN (7, 10, 12) # Completed, Canceled, Duplicate
      AND p.accepteddate = '0000-00-00 00:00:00'
      AND o.ordereddate >= @startDate
GROUP BY 1;


SELECT
  p.part_label
  , COUNT(*)
FROM orders o
  JOIN order_parts p ON p.orderid = o.id
WHERE o.companyid = 1
      AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
      AND o.order_type <> 45 # Trip Fee
      AND o.ordereddate >= @startDate
GROUP BY 1;

SELECT o.id
FROM orders o
  JOIN order_parts p ON p.orderid = o.id AND p.part_label = 'B'
WHERE o.companyid = 1
      AND p.part_type NOT IN (2, 3) # Exterior, Interior, AVM
      AND o.ordereddate >= @startDate;


# SELECT
#   NOW()
# #   , UTC_TIMESTAMP()
# #   , FROM_UNIXTIME(UNIX_TIMESTAMP())
#   , CONVERT_TZ(NOW(), 'UTC', 'US/Pacific')
# ;


# 289633

SELECT
  YEAR(o.ordereddate)
  , COUNT(*)
FROM orders o
  JOIN order_parts p ON p.orderid = o.id
WHERE o.companyid = 1
GROUP BY 1;


SELECT
  p.part_type
  , pt.descrip
  , COUNT(*)
FROM orders o
  JOIN order_parts p ON o.id = p.orderid
  JOIN part_types pt ON pt.id = p.part_type
GROUP BY 1, 2;


SELECT *
FROM part_types;
#
# SELECT *
# FROM order_status

SELECT *
FROM order_types;

SELECT
  c.companyname 'Company'
  , ot.descrip 'Product'
  , d.part_label 'Label'
  , d.fee 'Default Vendor Fee'
FROM default_vendor_fee d
  JOIN order_types ot ON ot.id = d.order_type
  JOIN companies c ON c.id = d.companyid
WHERE d.companyid IN (1, 2)
ORDER BY 1, 2, 3;

SET @fromDate = '2015-08-01';
SET @toDate = '2015-08-31';

SELECT
  `orders`.`ordereddate`
  , (CASE WHEN clients_v_transactions.id IS NULL THEN clients_v_order.client_name
     ELSE clients_v_transactions.client_name END) AS `client_name`
  , `orders`.`loanreference`
  , `orders`.`id`
  , `orders`.`propertyaddress`
  , `orders`.`propertyaddress2`
  , `orders`.`propertycity`
  , `PostalCodes`.`County` AS propertycounty
  , `orders`.`propertystate`
  , `orders`.`propertyzipcode`
  , `order_types`.`descrip`
  , `orders`.`invoiceamount`
  , vendor_fee_totals.total
  , `client_transactions`.`dts`
  , `orders`.`bulk_project_name`
  , (CASE WHEN `orders`.`partner_reference_num` IS NULL THEN `orders`.`client_reference_num`
     ELSE `orders`.`partner_reference_num` END) AS `client_reference_num`
  , (CASE WHEN admin_v_transactions.userid IS NULL THEN
  GROUP_CONCAT(CONCAT(admin_v_order.firstname, " ", admin_v_order.lastname))
     ELSE GROUP_CONCAT(CONCAT(admin_v_order.firstname, " ", admin_v_order.lastname)) END) AS salesperson
  , `order_status`.descrip AS order_status
FROM
  `orders`
  INNER JOIN `order_types` ON (`orders`.`order_type` = `order_types`.`id`)
  INNER JOIN `order_status` ON orders.order_status = `order_status`.`id`
  LEFT JOIN `client_transactions` ON (`orders`.`id` = `client_transactions`.`orderid` AND `type` = "COMPLETED")
  LEFT JOIN `clients` AS clients_v_transactions ON (`client_transactions`.`clientid` = `clients_v_transactions`.`id`)
  LEFT JOIN `user_data_client` ON orders.`orderbyid` = user_data_client.`userid`
  LEFT JOIN `clients` AS clients_v_order ON clients_v_order.id = user_data_client.clientid
  LEFT JOIN PostalCodes ON (orders.propertyzipcode = PostalCodes.ZIPCode)
  LEFT JOIN
  (
    SELECT
      `orderid`
      , MAX(order_parts.`effective_date`) AS effective_date
      , SUM(`order_parts`.`vendorfee`) AS total
    FROM `order_parts`
    GROUP BY `orderid`
  ) AS vendor_fee_totals ON (`orders`.`id` = vendor_fee_totals.orderid)
  LEFT JOIN `clients_sales_persons` AS sales_persons_v_transactions
    ON (clients_v_transactions.id = sales_persons_v_transactions.clientid AND
        sales_persons_v_transactions.`commission` > 0)
  LEFT JOIN `clients_sales_persons` AS sales_persons_v_order
    ON (clients_v_order.id = sales_persons_v_order.clientid AND sales_persons_v_order.`commission` > 0)
  LEFT JOIN user_data_admin AS admin_v_transactions
    ON (sales_persons_v_transactions.adminid = admin_v_transactions.userid)
  LEFT JOIN user_data_admin AS admin_v_order ON (sales_persons_v_order.adminid = admin_v_order.userid)
WHERE
  (CASE
   WHEN `client_transactions`.`id` IS NULL
     THEN vendor_fee_totals.`effective_date` >= CONCAT(@fromDate, " 00:00:00") AND
          vendor_fee_totals.`effective_date` <= CONCAT(@toDate, " 23:59:59")
   ELSE `client_transactions`.`dts` >= CONCAT(@fromDate, " 00:00:00") AND
        `client_transactions`.`dts` <= CONCAT(@toDate, " 23:59:59")
   END) AND
  orders.order_status IN (7, 10, 14) AND
  orders.companyid = 1
GROUP BY orders.id;


SELECT COUNT(*)
FROM orders o
  JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
WHERE o.companyid = 1
      AND o.order_status IN (7, 10, 14) # Completed, Canceled, Reconsideration
      AND t.dts >= '2015-08-01 00:00:00' AND t.dts <= '2015-08-31 23:59:59';

SELECT
  o.id
  , SUM(p.vendorfee) AS total
FROM orders o
  JOIN order_parts p ON p.orderid = o.id
  JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
WHERE o.companyid = 1
      AND o.order_status IN (7, 10, 14) # Completed, Canceled, Reconsideration
      AND t.dts >= '2015-08-01 00:00:00' AND t.dts <= '2015-08-31 23:59:59'
GROUP BY o.id;


SELECT
  o.id 'Order No'
  , ot.descrip 'Product'
  , s.descrip 'Order Status'
  , x.effective_date
  , p.order_status
  , p.vendorfee
  , o.invoiceamount
FROM
  (
    SELECT
      o.id
      , MAX(p.effective_date) 'effective_date'
    FROM orders o
      JOIN order_parts p ON p.orderid = o.id
      LEFT JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
    WHERE o.companyid = 1
          AND o.order_status IN (7, 10, 14) # Completed, Canceled, Reconsideration
          AND p.effective_date >= '2015-08-01 00:00:00' AND p.effective_date <= '2015-08-31 23:59:59'
          AND t.dts IS NULL
    GROUP BY 1
  ) x
  JOIN orders o ON o.id = x.id
  JOIN order_parts p ON p.orderid = x.id
  JOIN order_status s ON s.id = o.order_status
  JOIN order_types ot ON ot.id = o.order_type;

SELECT *
FROM order_status;

SELECT
  p.order_status
  , SUM(p.vendorfee)
FROM orders o
  JOIN order_parts p ON p.orderid = o.id
  JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
WHERE o.companyid = 1
      AND o.order_type = 45
GROUP BY 1;

SELECT
  o.order_status
  , p.order_status
  , ot.descrip
  , SUM(p.vendorfee)
FROM orders o
  JOIN order_parts p ON p.orderid = o.id
  JOIN order_types ot ON ot.id = o.order_type
  LEFT JOIN client_transactions t ON t.orderid = o.id
WHERE o.companyid = 1
      AND o.order_status IN (7, 10, 14) # Completed, Canceled, Reconsideration
#     AND p.order_status = 10
      AND o.ordereddate >= '2015-01-01 00:00:00'
      AND p.vendorfee > 0
      AND t.dts IS NULL
GROUP BY 1, 2, 3;

SELECT
  o.id
  , o.ordereddate
  , ot.descrip
  , o.order_status
  , p.order_status
  , p.vendorfee
FROM orders o
  JOIN order_parts p ON p.orderid = o.id
  JOIN order_types ot ON ot.id = o.order_type
  LEFT JOIN client_transactions t ON t.orderid = o.id
WHERE o.companyid = 1
      AND o.order_status IN (7, 10, 14) # Completed, Canceled, Reconsideration
      AND p.order_status = 3
      AND o.ordereddate >= '2015-01-01 00:00:00'
      #       AND p.vendorfee > 0
      AND t.dts IS NULL;

# V2 Gear Orders

SELECT
  x.companyname 'Company'
  , o.id 'Order No'
  , DATE(o.ordereddate) 'Order Date'
  , NULL 'Completion Date'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , ot.descrip 'Product'
  , c.id 'Client No'
  , c.client_name 'Client Name'
  , s.descrip 'Order Status'
  , o.invoiceamount 'Invoice Amount'
FROM orders o
  JOIN order_parts p ON p.orderid = o.id
  JOIN order_types ot ON ot.id = o.order_type
  JOIN order_status s ON s.id = o.order_status
  JOIN companies x ON x.id = o.companyid
  JOIN user_data_client u ON u.userid = o.orderbyid
  LEFT JOIN clients c ON c.id = u.clientid
  LEFT JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
WHERE o.companyid IN (1, 2)
      AND t.dts IS NULL
      AND p.part_type = 12 # GEAR AP
UNION
SELECT
  x.companyname 'Company'
  , o.id 'Order No'
  , DATE(o.ordereddate) 'Order Date'
  , DATE(t.dts) 'Completion Date'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , ot.descrip 'Product'
  , c.id 'Client No'
  , c.client_name 'Client Name'
  , s.descrip 'Order Status'
  , t.amount 'Invoice Amount'
FROM orders o
  JOIN order_parts p ON p.orderid = o.id
  JOIN order_types ot ON ot.id = o.order_type
  JOIN order_status s ON s.id = o.order_status
  JOIN companies x ON x.id = o.companyid
  JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
  LEFT JOIN clients AS c ON c.id = t.clientid
WHERE o.companyid IN (1, 2)
      AND p.part_type = 12 # GEAR AP
ORDER BY 1, 3;

SELECT *
FROM clients c
WHERE c.client_name LIKE 'NV%';

SELECT
  o.id 'Order No'
  , o.companyid
  , o.order_status
  , DATE(o.ordereddate) 'Order Date'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
FROM orders o
  JOIN user_data_client u ON u.userid = o.orderbyid
  LEFT JOIN clients c ON c.id = u.clientid
WHERE c.id = 191;


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


SELECT
  s.statement_date 'Statement Date'
  , c.client_name 'Client Name'
  , SUM(o.invoiceamount) 'Invoice Amount'
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
GROUP BY 1, 2;


SELECT
  CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'Vendor Name'
  , COUNT(*)
FROM orders o
  JOIN order_parts p ON p.orderid = o.id
  JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
  JOIN user_data_vendor v ON v.userid = p.acceptedby
WHERE o.companyid = 1
      AND o.order_status IN (7, 14) # Completed, Reconsideration
      AND p.order_status = 7
      AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
      AND t.dts >= '2015-08-01 00:00:00' AND t.dts < '2015-09-01 00:00:00'
GROUP BY 1;

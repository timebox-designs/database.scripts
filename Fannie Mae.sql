# SALES

# SELECT
#   x.Month
#   , x.Sales
#   , y.Fees 'Vendor Fees'
#   , ROUND(y.Fees / x.Sales * 100, 2) 'COGS %'
# FROM
#   (
#     SELECT
#       MONTHNAME(t.dts) 'Month'
#       , SUM(t.amount) 'Sales'
#     FROM orders o
#       JOIN client_transactions t ON t.orderid = o.id
#     WHERE o.companyid = 1
#           AND o.order_status = 7
#           AND t.dts >= '2015-05-01 00:00:00' AND t.dts < '2015-08-01 00:00:00'
#     GROUP BY MONTH(t.dts)
#   ) x
#   JOIN
#   (
#     SELECT
#       MONTHNAME(t.dts) 'Month'
#       , SUM(p.vendorfee) 'Fees'
#     FROM orders o
#       JOIN order_parts p ON p.orderid = o.id
#       JOIN client_transactions t ON t.orderid = o.id
#     WHERE o.companyid = 1
#           AND o.order_status = 7
#           AND p.order_status = 7
#           AND t.dts >= '2015-05-01 00:00:00' AND t.dts < '2015-08-01 00:00:00'
#     GROUP BY MONTH(t.dts)
#   ) y ON y.Month = x.Month;


# Fannie Mae (2015 YTD)

SELECT
  x.client_name 'Client Name'
  , o.id 'Order No.'
  , DATE(o.ordereddate) 'Order Date'
  , DATE(t.dts) 'Completion Date'
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
      , p.vendorfee 'fee'
    FROM orders o
      JOIN order_parts p ON o.id = p.orderid AND p.part_label = 'A'
      JOIN user_data_vendor v ON v.userid = p.acceptedby
      #       JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED' AND t.clientid = 17 # Fannie Mae
      JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
                                    AND t.clientid IN
                                        (313, 318, 319, 321, 320, 331, 178, 271, 187, 326, 315, 317, 316, 314, 324, 328, 329, 323, 332, 327, 325, 168, 330, 422, 163, 169, 166, 167)
    WHERE o.companyid = 1
          AND o.order_status = 7 # Completed
          AND p.order_status = 7 # Completed
          AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
          AND o.ordereddate >= '2015-01-01 00:00:00'
  ) a
  LEFT JOIN
  (
    SELECT
      o.id
      , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'vendor'
      , p.vendorfee 'fee'
    FROM orders o
      JOIN order_parts p ON o.id = p.orderid AND p.part_label = 'B'
      JOIN user_data_vendor v ON v.userid = p.acceptedby
      #       JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED' AND t.clientid = 17 # Fannie Mae
      JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
                                    AND t.clientid IN
                                        (313, 318, 319, 321, 320, 331, 178, 271, 187, 326, 315, 317, 316, 314, 324, 328, 329, 323, 332, 327, 325, 168, 330, 422, 163, 169, 166, 167)
    WHERE o.companyid = 1
          AND o.order_status = 7 # Completed
          AND p.order_status = 7 # Completed
          AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
          AND o.ordereddate >= '2015-01-01 00:00:00'
  ) b ON b.id = a.id
  LEFT JOIN
  (
    SELECT
      o.id
      , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'vendor'
      , p.vendorfee 'fee'
    FROM orders o
      JOIN order_parts p ON o.id = p.orderid AND p.part_label = 'C'
      JOIN user_data_vendor v ON v.userid = p.acceptedby
      #       JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED' AND t.clientid = 17 # Fannie Mae
      JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
                                    AND t.clientid IN
                                        (313, 318, 319, 321, 320, 331, 178, 271, 187, 326, 315, 317, 316, 314, 324, 328, 329, 323, 332, 327, 325, 168, 330, 422, 163, 169, 166, 167)
    WHERE o.companyid = 1
          AND o.order_status = 7 # Completed
          AND p.order_status = 7 # Completed
          AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
          AND o.ordereddate >= '2015-01-01 00:00:00'
  ) c ON c.id = a.id
  JOIN orders o ON o.id = a.id
  JOIN order_types ot ON ot.id = o.order_type
  JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
  JOIN clients x ON x.id = t.clientid
ORDER BY t.dts;

# Orders

SELECT
  c.client_name 'Client Name'
  , o.id 'Order No'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , ot.descrip 'Product/Service'
  , t.amount 'Invoice Amount'
  , DATE(o.ordereddate) 'Order Date'
  , DATE(t.dts) 'Completed Date'
  , ROUND(TIME_TO_SEC(TIMEDIFF(t.dts, o.ordereddate)) / 3600, 2) 'Turn Time (Hours)'
FROM orders o
  JOIN order_types ot ON ot.id = o.order_type
  JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
  #   JOIN clients c ON c.id = t.clientid AND c.id = 17 # Fannie Mae
  JOIN clients c ON c.id = t.clientid
                    AND c.id IN
                        (313, 318, 319, 321, 320, 331, 178, 271, 187, 326, 315, 317, 316, 314, 324, 328, 329, 323, 332, 327, 325, 168, 330, 422, 163, 169, 166, 167)
WHERE o.companyid = 1
      AND o.order_status = 7
      AND o.ordereddate >= '2015-01-01 00:00:00'
ORDER BY o.ordereddate, t.dts;

# Parts

SELECT
  o.id 'Order No'
  , o.ordereddate 'Order Date'
  , p.accepteddate 'Accepted Date'
  , p.start_dts 'Start Date'
  , p.effective_date 'Effective Date'
  , t.dts 'Completed Date'
  , ROUND(TIME_TO_SEC(TIMEDIFF(p.accepteddate, o.ordereddate)) / 3600, 2) 'Placement Delay (Hours)'
  , ROUND(TIME_TO_SEC(TIMEDIFF(p.start_dts, p.accepteddate)) / 3600, 2) 'Start Delay (Hours)'
  , ROUND(TIME_TO_SEC(TIMEDIFF(p.effective_date, p.accepteddate)) / 3600, 2) 'Turn Time (Hours)'
  , p.part_label 'Label'
  , p.acceptedby 'Vendor No'
  , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'Vendor Name'
  , p.vendorfee 'Vendor Fee'
FROM orders o
  JOIN order_parts p ON p.orderid = o.id
  JOIN user_data_vendor v ON v.userid = p.acceptedby
  JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
  #   JOIN clients c ON c.id = t.clientid AND c.id = 17 # Fannie Mae
  JOIN clients c ON c.id = t.clientid
                    AND c.id IN
                        (313, 318, 319, 321, 320, 331, 178, 271, 187, 326, 315, 317, 316, 314, 324, 328, 329, 323, 332, 327, 325, 168, 330, 422, 163, 169, 166, 167)
WHERE o.companyid = 1
      AND o.order_status = 7
      AND p.order_status = 7
      AND p.part_type NOT IN (2, 3, 4) # Exterior, Interior, AVM
      AND o.ordereddate >= '2015-01-01 00:00:00'
ORDER BY o.id, p.part_label;

# 115 Morgan Stanley
# 216 J.P. Morgan

SELECT *
FROM clients c
WHERE c.client_name LIKE 'Solution%'

# Solution Star (313,318,319,321,320,331,178,271,187,326,315,317,316,314,324,328,329,323,332,327,325,168,330,422,163,169,166,167)

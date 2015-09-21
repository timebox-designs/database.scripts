SET @MonthEnd = DATE_ADD(MAKEDATE(2015, 1), INTERVAL 7 MONTH);
;

SET @30Day = SUBDATE(@MonthEnd, INTERVAL 30 DAY)
;

SET @60Day = SUBDATE(@MonthEnd, INTERVAL 60 DAY)
;

SET @90Day = SUBDATE(@MonthEnd, INTERVAL 90 DAY)
;

# SET @Vendor = 166055 # Patti Pruitt
# SET @Vendor = 4313 # Amalia Montes
# SET @Vendor = 167388 # Adabel Ramos
SET @Vendor = 919 # Dana Farber
;

SELECT
  # current
  @30day '>='
  , @MonthEnd '<'
UNION
SELECT
  # 30 day
  @60day '>='
  , @30day '<'
UNION
SELECT
  # 60 day
  @90day '>='
  , @60day '<'
UNION
SELECT
  # 90 day
  NULL '<'
  , @90day '>='
;

SELECT
  v.userid 'Vendor No'
  , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'Vendor Name'
  , o.id 'Order No'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , ot.descrip 'Product/Service'
  , p.part_label 'Label'
  , pt.descrip 'Part Type'
  , p.vendorfee 'Vendor Fee'
  , DATE(t.dts) 'Date Completed'
  , DATE(vendor_paid) 'Vendor Paid'
  , DATEDIFF(@MonthEnd, t.dts) 'Date Difference'
  , CASE WHEN t.dts >= @30Day AND t.dts < @MonthEnd THEN 'Current'
    ELSE CASE WHEN t.dts >= @60Day AND t.dts < @30Day THEN '30 Day'
         ELSE CASE WHEN t.dts >= @90Day AND t.dts < @60Day THEN '60 Day'
              ELSE CASE WHEN t.dts < @90Day THEN '90 Day'
                   END
              END
         END
    END 'Date Bucket'
FROM orders o
  JOIN order_parts p ON o.id = p.orderid
  JOIN order_types ot ON ot.id = o.order_type
  JOIN part_types pt ON pt.id = p.part_type
  JOIN user_data_vendor v ON v.userid = p.acceptedby
  LEFT JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
WHERE o.companyid = 1
      AND o.order_status = 7 # Completed
      AND p.order_status = 7 # Completed
      AND p.acceptedby = @Vendor
      AND t.dts < @MonthEnd
ORDER BY t.dts, o.id, p.part_label
;

SELECT
  v.userid 'Vendor No'
  , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'Vendor Name'
  , o.id 'Order No'
  , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
  , ot.descrip 'Product/Service'
  , x.label 'Label'
  , x.fee 'Vendor Fee'
  , DATE(x.completed) 'Date Completed'
  , DATE(x.paid) 'Vendor Paid'
  , DATEDIFF(@MonthEnd, x.completed) 'Date Difference'
  , CASE WHEN x.completed >= @30Day AND x.completed < @MonthEnd THEN 'Current'
    ELSE CASE WHEN x.completed >= @60Day AND x.completed < @30Day THEN '30 Day'
         ELSE CASE WHEN x.completed >= @90Day AND x.completed < @60Day THEN '60 Day'
              ELSE CASE WHEN x.completed < @90Day THEN '90 Day'
                   END
              END
         END
    END 'Date Bucket'
FROM
  (
    SELECT
      p.acceptedby
      , o.id
      , p.part_label 'label'
      , SUM(p.vendorfee) 'fee'
      , MAX(t.dts) 'completed'
      , MAX(p.vendor_paid) 'paid'
    FROM orders o
      JOIN order_parts p ON o.id = p.orderid
      LEFT JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
    WHERE o.companyid = 1
          AND o.order_status = 7 # Completed
          AND p.order_status = 7 # Completed
          AND p.acceptedby = @Vendor
          AND t.dts < @MonthEnd
    #               AND t.dts IS NULL
    GROUP BY 1, 2, 3
  ) x
  JOIN orders o ON o.id = x.id
  JOIN order_types ot ON ot.id = o.order_type
  JOIN user_data_vendor v ON v.userid = x.acceptedby
ORDER BY x.completed, o.id
;


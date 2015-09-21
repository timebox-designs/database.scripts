SET @startDate = '2015-01-01 00:00:00';
SET @endDate = '2015-09-01 00:00:00';


SELECT
  ot.descrip 'Product/Service'
  , SUM(t.amount) 'Revenue'
FROM orders o
  JOIN order_types ot ON ot.id = o.order_type
  JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
WHERE o.companyid = 1
      AND o.order_status = 7
      AND t.dts >= @startDate AND t.dts < @endDate
GROUP BY ot.descrip;


# By Product (2015 YTD)

SELECT
  z.descrip 'Product/Service'
  , x.month 'Month'
  , x.count 'Orders'
  , x.revenue 'Revenue'
  , y.fees 'Vendor Fees'
FROM
  (
    SELECT
      o.order_type
      , MONTH(t.dts) 'month'
      , SUM(t.amount) 'revenue'
      , COUNT(*) 'count'
    FROM orders o
      JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED' AND t.clientid = 2
    WHERE o.companyid = 1
          AND o.order_status = 7
          AND t.dts >= @startDate AND t.dts < @endDate
    GROUP BY o.order_type, MONTH(t.dts)
  ) x
  JOIN
  (
    SELECT
      o.order_type
      , MONTH(t.dts) 'month'
      , SUM(IFNULL(p.vendorfee, 0)) 'fees'
    FROM orders o
      JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED' AND t.clientid = 2
      LEFT JOIN order_parts p ON p.orderid = o.id # Not all orders have parts
    WHERE o.companyid = 1
          AND o.order_status = 7
          AND t.dts >= @startDate AND t.dts < @endDate
    GROUP BY o.order_type, MONTH(t.dts)
  ) y ON y.order_type = x.order_type AND y.month = x.month
  JOIN order_types z ON z.id = x.order_type;


# By Client (2015 YTD)

SELECT
  z.client_name 'Client'
  , x.month 'Month'
  , x.count 'Orders'
  , x.revenue 'Revenue'
  , y.fees 'Vendor Fees'
FROM
  (
    SELECT
      t.clientid
      , MONTH(t.dts) 'month'
      , SUM(t.amount) 'revenue'
      , COUNT(*) 'count'
    FROM orders o
      JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
    WHERE o.companyid = 1
          AND o.order_status = 7
          AND t.dts >= @startDate AND t.dts < @endDate
    GROUP BY t.clientid, MONTH(t.dts)
  ) x
  JOIN
  (
    SELECT
      t.clientid
      , MONTH(t.dts) 'month'
      , SUM(IFNULL(p.vendorfee, 0)) 'fees'
    FROM orders o
      JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
      LEFT JOIN order_parts p ON p.orderid = o.id # Not all orders have parts
    WHERE o.companyid = 1
          AND o.order_status = 7
          AND t.dts >= @startDate AND t.dts < @endDate
    GROUP BY t.clientid, MONTH(t.dts)
  ) y ON y.clientid = x.clientid AND y.month = x.month
  JOIN clients z ON z.id = x.clientid AND z.id = 2;


# SELECT COUNT(*)
# FROM orders o
#   JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
# WHERE o.companyid = 1
#       AND o.order_status IN (7)
#       AND t.dts >= @startDate AND t.dts < @endDate;


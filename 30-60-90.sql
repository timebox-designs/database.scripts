SET @month = 8;
SET @year = 2015;
SET @monthEnd = DATE_ADD(MAKEDATE(@year, 1), INTERVAL @month MONTH);

CALL OutstandingVendorFees(@month, @year);
CALL OutstandingVendorOrders(@month, @year);
CALL OutstandingVendorFeesXRef(@month, @year);

# Fannie Mae

SELECT
  v.userid 'Vendor No'
  , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'Vendor Name'
FROM
  (
    SELECT p.acceptedby
    FROM order_parts p
      JOIN client_transactions t ON t.orderid = p.orderid AND t.type = 'COMPLETED'
    WHERE t.clientid = 17 # Fannie Mae
          AND t.dts < @monthEnd
    GROUP BY 1
    HAVING SUM(p.vendorfee) > 0
  ) x
  JOIN user_data_vendor v ON v.userid = x.acceptedby
ORDER BY 1;

# Trip Fees (without transactions)

SELECT
  p.acceptedby 'vendorid'
  , SUM(CASE WHEN p.vendor_paid > '0000-00-00 00:00:00' THEN p.vendorfee ELSE 0 END) 'paid'
  , SUM(CASE WHEN p.vendor_paid = '0000-00-00 00:00:00' THEN p.vendorfee ELSE 0 END) 'outstanding'
FROM orders o
  JOIN order_parts p ON o.id = p.orderid
  LEFT JOIN client_transactions t ON t.orderid = o.id
WHERE o.companyid = 1
      AND o.order_status = 7 # Completed
      AND p.order_status = 7 # Completed
      AND p.part_type = 9 # Trip Fee
      AND t.dts IS NULL
GROUP BY 1;

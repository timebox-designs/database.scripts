DROP PROCEDURE IF EXISTS OutstandingVendorOrders;

CREATE PROCEDURE OutstandingVendorOrders(month INT, year INT)
  BEGIN
    DECLARE monthEnd DATETIME;
    DECLARE _30Days DATETIME;
    DECLARE _60Days DATETIME;

    # We define "monthEnd" as midnight of the first day of the following month, in order to account for
    # the time portion of the DATETIME values.

    SET monthEnd = DATE_ADD(MAKEDATE(year, 1), INTERVAL month MONTH);

    SET _30Days = SUBDATE(monthEnd, INTERVAL 1 MONTH);
    SET _60Days = SUBDATE(monthEnd, INTERVAL 2 MONTH);

    SELECT
      a.acceptedby 'Vendor No'
      , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'Vendor Name'
      , u.email 'Vendor Email'
      , UPPER(v.compstate) 'Vendor State'
      , CASE WHEN s.segmentid = 11 THEN 'Y' ELSE 'N' END 'Preferred'
      , IFNULL(b.orders_outstanding, 0) '30 Day'
      , IFNULL(c.orders_outstanding, 0) '60 Day'
      , IFNULL(d.orders_outstanding, 0) '90 Day'
      , IFNULL(a.orders_outstanding, 0) 'Outstanding Orders'
      , IFNULL(a.orders_outstanding, 0) + IFNULL(a.orders_paid, 0) 'Total Orders'
    FROM
      (
        SELECT
          x.acceptedby
          , SUM(CASE WHEN x.type = 1 THEN 1 ELSE 0 END) 'orders_paid'
          , SUM(CASE WHEN x.type = 0 THEN 1 ELSE 0 END) 'orders_outstanding'
          , SUM(x.paid) 'fees_paid'
          , SUM(x.outstanding) 'fees_outstanding'
        FROM
          (
            SELECT
              p.acceptedby
              , o.id
              , p.part_label
              , SUM(CASE WHEN p.vendor_paid = '0000-00-00 00:00:00' THEN p.vendorfee ELSE 0 END) 'outstanding' # is null
              , SUM(CASE WHEN p.vendor_paid > '0000-00-00 00:00:00' THEN p.vendorfee ELSE 0 END) 'paid' # is not null
              , CASE WHEN p.vendor_paid > '0000-00-00 00:00:00' THEN 1 ELSE 0 END 'type'
            FROM orders o
              JOIN order_parts p ON o.id = p.orderid
              JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
            WHERE o.companyid = 1
                  AND o.order_status = 7 # Completed
                  AND p.order_status = 7 # Completed
                  AND t.dts < monthEnd
            GROUP BY 1, 2, 3
          ) x
        GROUP BY 1
      ) a
      LEFT JOIN
      (
        SELECT
          x.acceptedby
          , SUM(CASE WHEN x.type = 1 THEN 1 ELSE 0 END) 'orders_paid'
          , SUM(CASE WHEN x.type = 0 THEN 1 ELSE 0 END) 'orders_outstanding'
          , SUM(x.paid) 'fees_paid'
          , SUM(x.outstanding) 'fees_outstanding'
        FROM
          (
            SELECT
              p.acceptedby
              , o.id
              , p.part_label
              , SUM(CASE WHEN p.vendor_paid = '0000-00-00 00:00:00' THEN p.vendorfee ELSE 0 END) 'outstanding' # is null
              , SUM(CASE WHEN p.vendor_paid > '0000-00-00 00:00:00' THEN p.vendorfee ELSE 0 END) 'paid' # is not null
              , CASE WHEN p.vendor_paid > '0000-00-00 00:00:00' THEN 1 ELSE 0 END 'type'
            FROM orders o
              JOIN order_parts p ON o.id = p.orderid
              JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
            WHERE o.companyid = 1
                  AND o.order_status = 7 # Completed
                  AND p.order_status = 7 # Completed
                  AND t.dts >= _30Days AND t.dts < monthEnd
            GROUP BY 1, 2, 3
          ) x
        GROUP BY 1
      ) b ON b.acceptedby = a.acceptedby
      LEFT JOIN
      (
        SELECT
          x.acceptedby
          , SUM(CASE WHEN x.type = 1 THEN 1 ELSE 0 END) 'orders_paid'
          , SUM(CASE WHEN x.type = 0 THEN 1 ELSE 0 END) 'orders_outstanding'
          , SUM(x.paid) 'fees_paid'
          , SUM(x.outstanding) 'fees_outstanding'
        FROM
          (
            SELECT
              p.acceptedby
              , o.id
              , p.part_label
              , SUM(CASE WHEN p.vendor_paid = '0000-00-00 00:00:00' THEN p.vendorfee ELSE 0 END) 'outstanding' # is null
              , SUM(CASE WHEN p.vendor_paid > '0000-00-00 00:00:00' THEN p.vendorfee ELSE 0 END) 'paid' # is not null
              , CASE WHEN p.vendor_paid > '0000-00-00 00:00:00' THEN 1 ELSE 0 END 'type'
            FROM orders o
              JOIN order_parts p ON o.id = p.orderid
              JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
            WHERE o.companyid = 1
                  AND o.order_status = 7 # Completed
                  AND p.order_status = 7 # Completed
                  AND t.dts >= _60Days AND t.dts < _30Days
            GROUP BY 1, 2, 3
          ) x
        GROUP BY 1
      ) c ON c.acceptedby = a.acceptedby
      LEFT JOIN
      (
        SELECT
          x.acceptedby
          , SUM(CASE WHEN x.type = 1 THEN 1 ELSE 0 END) 'orders_paid'
          , SUM(CASE WHEN x.type = 0 THEN 1 ELSE 0 END) 'orders_outstanding'
          , SUM(x.paid) 'fees_paid'
          , SUM(x.outstanding) 'fees_outstanding'
        FROM
          (
            SELECT
              p.acceptedby
              , o.id
              , p.part_label
              , SUM(CASE WHEN p.vendor_paid = '0000-00-00 00:00:00' THEN p.vendorfee ELSE 0 END) 'outstanding' # is null
              , SUM(CASE WHEN p.vendor_paid > '0000-00-00 00:00:00' THEN p.vendorfee ELSE 0 END) 'paid' # is not null
              , CASE WHEN p.vendor_paid > '0000-00-00 00:00:00' THEN 1 ELSE 0 END 'type'
            FROM orders o
              JOIN order_parts p ON o.id = p.orderid
              JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
            WHERE o.companyid = 1
                  AND o.order_status = 7 # Completed
                  AND p.order_status = 7 # Completed
                  AND t.dts < _60Days
            GROUP BY 1, 2, 3
          ) x
        GROUP BY 1
      ) d ON d.acceptedby = a.acceptedby
      JOIN user_data_vendor v ON v.userid = a.acceptedby
      JOIN user u ON u.id = v.userid
      LEFT JOIN user_vendor_segments s ON s.userid = a.acceptedby
    WHERE a.fees_outstanding > 0
    ORDER BY 9 DESC, 2;
  END;

# CALL OutstandingVendorOrders(7, 2015);

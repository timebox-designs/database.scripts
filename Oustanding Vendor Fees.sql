DROP PROCEDURE IF EXISTS OutstandingVendorFees;

CREATE PROCEDURE OutstandingVendorFees(month INT, year INT)
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
      , IFNULL(b.fees_outstanding, 0) '30 Day'
      , IFNULL(c.fees_outstanding, 0) '60 Day'
      , IFNULL(d.fees_outstanding, 0) '90 Day'
      , IFNULL(a.fees_outstanding, 0) 'Outstanding Fees'
      , IFNULL(a.fees_outstanding, 0) + IFNULL(a.fees_paid, 0) 'Total Fees'
    FROM
      (
        SELECT
          x.acceptedby
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
          p.acceptedby
          , SUM(p.vendorfee) 'fees_outstanding'
        FROM orders o
          JOIN order_parts p ON o.id = p.orderid
          JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
        WHERE o.companyid = 1
              AND o.order_status = 7 # Completed
              AND p.order_status = 7 # Completed
              AND p.vendor_paid = '0000-00-00 00:00:00' # is null
              AND t.dts >= _30Days AND t.dts < monthEnd
        GROUP BY 1
      ) b ON b.acceptedby = a.acceptedby
      LEFT JOIN
      (
        SELECT
          p.acceptedby
          , SUM(p.vendorfee) 'fees_outstanding'
        FROM orders o
          JOIN order_parts p ON o.id = p.orderid
          JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
        WHERE o.companyid = 1
              AND o.order_status = 7 # Completed
              AND p.order_status = 7 # Completed
              AND p.vendor_paid = '0000-00-00 00:00:00' # is null
              AND t.dts >= _60Days AND t.dts < _30Days
        GROUP BY 1
      ) c ON c.acceptedby = a.acceptedby
      LEFT JOIN
      (
        SELECT
          p.acceptedby
          , SUM(p.vendorfee) 'fees_outstanding'
        FROM orders o
          JOIN order_parts p ON o.id = p.orderid
          JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
        WHERE o.companyid = 1
              AND o.order_status = 7 # Completed
              AND p.order_status = 7 # Completed
              AND p.vendor_paid = '0000-00-00 00:00:00' # is null
              AND t.dts < _60Days
        GROUP BY 1
      ) d ON d.acceptedby = a.acceptedby
      JOIN user_data_vendor v ON v.userid = a.acceptedby
      JOIN user u ON u.id = v.userid
      LEFT JOIN user_vendor_segments s ON s.userid = a.acceptedby
    WHERE a.fees_outstanding > 0
    ORDER BY 9 DESC, 2;
  END;

# CALL OutstandingVendorFees(7, 2015);

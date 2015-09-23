DROP PROCEDURE IF EXISTS OutstandingVendorFeesXRef;

CREATE PROCEDURE OutstandingVendorFeesXRef(month INT, year INT)
  BEGIN
    DECLARE monthEnd DATETIME;

    # We define "monthEnd" as midnight of the first day of the following month, in order to account for
    # the time portion of the DATETIME values.

    SET monthEnd = DATE_ADD(MAKEDATE(year, 1), INTERVAL month MONTH);

    # In order to deal with the suck, we first create a temporary table to split the comma separated part id's
    # into separate rows.

    CREATE TEMPORARY TABLE parts AS
      SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(c.partids, ',', n.n), ',', -1) 'id'
      FROM vendor_checks c CROSS JOIN
        (
          SELECT (a.n * 100 + b.n * 10 + c.n + 1) n
          FROM
            (SELECT 0 n
             UNION ALL SELECT 1 n
             UNION ALL SELECT 2 n
             UNION ALL SELECT 3 n
             UNION ALL SELECT 4 n
             UNION ALL SELECT 5 n
             UNION ALL SELECT 6 n
             UNION ALL SELECT 7 n
             UNION ALL SELECT 8 n
             UNION ALL SELECT 9 n) a,
            (SELECT 0 n
             UNION ALL SELECT 1 n
             UNION ALL SELECT 2 n
             UNION ALL SELECT 3 n
             UNION ALL SELECT 4 n
             UNION ALL SELECT 5 n
             UNION ALL SELECT 6 n
             UNION ALL SELECT 7 n
             UNION ALL SELECT 8 n
             UNION ALL SELECT 9 n) b,
            (SELECT 0 n
             UNION ALL SELECT 1 n
             UNION ALL SELECT 2 n
             UNION ALL SELECT 3 n
             UNION ALL SELECT 4 n
             UNION ALL SELECT 5 n
             UNION ALL SELECT 6 n
             UNION ALL SELECT 7 n
             UNION ALL SELECT 8 n
             UNION ALL SELECT 9 n) c
          ORDER BY n
        ) n
      WHERE CHAR_LENGTH(c.partids) - CHAR_LENGTH(REPLACE(c.partids, ',', '')) + 1 >= n.n
            AND c.companyid = 1;

    # Now we use the fruits of our labour to pull the results.

    SELECT
      p.acceptedby 'vendorid'
      , SUM(p.vendorfee) 'paid'
    FROM parts x
      JOIN order_parts p ON p.id = x.id
      JOIN client_transactions t ON t.orderid = p.orderid AND t.type = 'COMPLETED'
    WHERE t.dts < monthEnd
    GROUP BY 1;

    # And lastly, we clean up after ourselves.

    DROP TEMPORARY TABLE IF EXISTS parts;
  END;

CALL OutstandingVendorFeesXRef(8, 2015);

# Duplicate Checks
#
# SET @vendor = 8419;
#
# SELECT
#   v.userid 'Vendor No'
#   , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'Vendor Name'
#   , p.orderid 'Order No.'
#   , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
#   , p.vendorfee 'Vendor Fee'
#   , c.checknumber 'Check No.'
#   , c.dts 'Vendor Check Timestamp'
#   , p.vendor_paid 'Vendor Paid Timestamp'
# FROM vendor_checks c,
#   (
#     SELECT p.id
#     FROM vendor_checks c, order_parts p
#     WHERE FIND_IN_SET(p.id, c.partids)
#           AND c.companyid = 1
#           AND c.vendorid = @vendor
#           AND p.acceptedby = @vendor
#           AND p.vendorfee > 0
#     GROUP BY 1
#     HAVING COUNT(*) > 1
#   ) x
#   JOIN order_parts p ON p.id = x.id
#   JOIN orders o ON o.id = p.orderid
#   JOIN user_data_vendor v ON v.userid = p.acceptedby
# WHERE FIND_IN_SET(x.id, c.partids)
# ORDER BY p.orderid, c.checknumber;

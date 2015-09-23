DROP PROCEDURE IF EXISTS OutstandingVendorFeesDetail;

CREATE PROCEDURE OutstandingVendorFeesDetail(month INT, year INT, vendor INT)
  BEGIN
    DECLARE monthEnd DATETIME;
    DECLARE _30Days DATETIME;
    DECLARE _60Days DATETIME;
    DECLARE _90Days DATETIME;
    DECLARE _180Days DATETIME;
    DECLARE _365Days DATETIME;

    # We define "monthEnd" as midnight of the first day of the following month, in order to account for
    # the time portion of the DATETIME values.

    SET monthEnd = DATE_ADD(MAKEDATE(year, 1), INTERVAL month MONTH);

    SET _30Days = SUBDATE(monthEnd, INTERVAL 1 MONTH);
    SET _60Days = SUBDATE(monthEnd, INTERVAL 2 MONTH);
    SET _90Days = SUBDATE(monthEnd, INTERVAL 3 MONTH);
    SET _180Days = SUBDATE(monthEnd, INTERVAL 6 MONTH);
    SET _365Days = SUBDATE(monthEnd, INTERVAL 12 MONTH);

    SELECT
      v.userid 'Vendor No'
      , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'Vendor Name'
      , o.id 'Order No'
      , DATE(o.ordereddate) 'Order Date'
      , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
      , ot.descrip 'Product'
      , pt.descrip 'Part Type'
      , p.part_label 'Label'
      , p.vendorfee 'Vendor Fee'
      , DATE(vendor_paid) 'Vendor Paid'
      , c.checknumber 'Check No'
      , DATE(t.dts) 'Date Completed'
      , CASE
        WHEN t.dts >= _30Days AND t.dts < monthEnd THEN '30 Day'
        WHEN t.dts >= _60Days AND t.dts < _30Days THEN '60 Day'
        WHEN t.dts >= _90Days AND t.dts < _60Days THEN '90 Day'
        WHEN t.dts >= _180Days AND t.dts < _90Days THEN '4-6 Mths'
        WHEN t.dts >= _365Days AND t.dts < _180Days THEN '7-12 Mths'
        WHEN t.dts < _365Days THEN '1 Year+'
        END 'Date Bucket'
    FROM orders o
      JOIN order_parts p ON p.orderid = o.id
      JOIN order_types ot ON ot.id = o.order_type
      JOIN part_types pt ON pt.id = p.part_type
      JOIN user_data_vendor v ON v.userid = p.acceptedby
      LEFT JOIN client_transactions t ON t.orderid = o.id AND t.type = 'COMPLETED'
      LEFT JOIN
      (
        SELECT
          p.id
          , c.checknumber
        FROM vendor_checks c, order_parts p
        WHERE FIND_IN_SET(p.id, c.partids)
              AND p.acceptedby = vendor
      ) c ON c.id = p.id
    WHERE o.companyid = 1
          AND o.order_status IN (7, 14) # Completed, Reconsideration
          AND p.order_status = 7 # Completed
          AND p.acceptedby = vendor
          AND (t.dts < monthEnd OR t.dts IS NULL)
    ORDER BY t.dts, o.ordereddate, p.part_label;
  END;

CALL OutstandingVendorFeesDetail(8, 2015, 1241);

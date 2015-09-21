# DROP PROCEDURE IF EXISTS Week;
#
# CREATE PROCEDURE Week(week INT)
#   BEGIN
#     DECLARE priorYearEnd DATETIME;
#     DECLARE startDate DATETIME;
#     DECLARE endDate DATETIME;
#
#     # Base the date range off the prior year end date.
#     # Note: this is only good for 2015.
#
#     SET priorYearEnd = '2014-12-19 00:00:00';
#
#     SET endDate = DATE_ADD(priorYearEnd, INTERVAL week * 7 DAY);
#     SET startDate = DATE_SUB(endDate, INTERVAL 13 DAY);
#
#     SELECT
#       startDate
#       , endDate;
#   END;
#
# CALL Week(36);

DROP PROCEDURE IF EXISTS StaffAppraiserWeeklyReport;

CREATE PROCEDURE StaffAppraiserWeeklyReport(week INT)
  BEGIN
    DECLARE priorYearEnd DATETIME;
    DECLARE startDate DATETIME;
    DECLARE endDate DATETIME;

    # Base the date range off the prior year end date.
    # Note: this is only good for 2015.

    SET priorYearEnd = '2014-12-19 00:00:00';

    SET endDate = DATE_ADD(priorYearEnd, INTERVAL week * 7 DAY);
    SET startDate = DATE_SUB(endDate, INTERVAL 13 DAY);

    SELECT
      p.acceptedby 'Vendor No.'
      , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'Vendor Name'
      , o.id 'Order No'
      , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
      , DATE(o.ordereddate) 'Order Date'
      , DATE(p.accepteddate) 'Accepted Date'
      , x.date 'Date Completed/Canceled'
      , s.descrip 'Status'
      , ot.descrip 'Product/Service'
      , o.invoiceamount 'Invoice Amount'
      , c.client_name 'Client Name'
    FROM
      (
        SELECT
          p.id
          , t.clientid 'clientid'
          , DATE(t.dts) 'date' # completed date
        FROM orders o
          JOIN order_parts p ON p.orderid = o.id
          LEFT JOIN client_transactions t ON t.orderid = o.id
        WHERE o.order_status = 7
              AND (t.dts BETWEEN startDate AND endDate OR t.dts IS NULL)
              AND p.acceptedby IN
                  (
                    169057,
                    169210,
                    170390,
                    170518,
                    170575,
                    171146,
                    166658,
                    171421,
                    174326
                  )
        UNION
        SELECT
          p.id
          , c.id 'clientid'
          , DATE(p.canceled_dts) 'date' # canceled date
        FROM orders o
          JOIN order_parts p ON p.orderid = o.id
          LEFT JOIN clients AS c ON c.userid = o.orderbyid
        WHERE o.order_status = 10
              AND (p.canceled_dts BETWEEN startDate AND endDate)
              AND p.acceptedby IN
                  (
                    169057,
                    169210,
                    170390,
                    170518,
                    170575,
                    171146,
                    166658,
                    171421,
                    174326
                  )
      ) x
      JOIN order_parts p ON p.id = x.id
      JOIN orders o ON o.id = p.orderid
      JOIN order_types ot ON ot.id = o.order_type
      JOIN order_status s ON s.id = o.order_status
      JOIN user_data_vendor v ON v.userid = p.acceptedby
      LEFT JOIN clients AS c ON c.id = x.clientid
    ORDER BY 1, 7;
  END;

CALL StaffAppraiserWeeklyReport(38) # increment by 2
;

# SELECT
#   v.userid 'Vendor No.'
#   , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'Vendor Name'
#   , v.compname 'Vendor Company'
#   , v.vendor_guidlines_accepted 'Vendor Guidelines Accepted'
#   , v.axis_approved 'Axis Approved'
#   , v.parent_user
# FROM user_data_vendor v
# WHERE v.userid IN
#       (
#         169057,
#         169210,
#         170390,
#         170518,
#         170575,
#         171146,
#         166658,
#         171421,
#         174326
#       )
# ORDER BY v.lastname, v.firstname;

# SELECT
#   p.acceptedby 'Vendor No.'
#   , CONCAT_WS(' ', TRIM(v.firstname), TRIM(v.lastname)) 'Vendor Name'
#   , o.id 'Order No'
#   , CONCAT_WS(' ', o.propertyaddress, o.propertycity, o.propertystate, o.propertyzipcode) 'Property Address'
#   , DATE(o.ordereddate) 'Order Date'
#   , DATE(p.accepteddate) 'Accepted Date'
#   , x.date 'Date Completed/Canceled'
#   , s.descrip 'Status'
#   , ot.descrip 'Product/Service'
#   , o.invoiceamount 'Invoice Amount'
#   , c.client_name 'Client Name'
# FROM
#   (
#     SELECT
#       p.id
#       , t.clientid 'clientid'
#       , DATE(t.dts) 'date' # completed date
#     FROM orders o
#       JOIN order_parts p ON p.orderid = o.id
#       LEFT JOIN client_transactions t ON t.orderid = o.id
#     WHERE o.order_status = 7
#           AND p.acceptedby IN
#               (
#                 169057,
#                 169210,
#                 170390,
#                 170518,
#                 170575,
#                 171146,
#                 166658,
#                 171421,
#                 174326
#               )
#     UNION
#     SELECT
#       p.id
#       , c.id 'clientid'
#       , DATE(p.canceled_dts) 'date' # canceled date
#     FROM orders o
#       JOIN order_parts p ON p.orderid = o.id
#       LEFT JOIN clients AS c ON c.userid = o.orderbyid
#     WHERE o.order_status = 10
#           AND p.acceptedby IN
#               (
#                 169057,
#                 169210,
#                 170390,
#                 170518,
#                 170575,
#                 171146,
#                 166658,
#                 171421,
#                 174326
#               )
#   ) x
#   JOIN order_parts p ON p.id = x.id
#   JOIN orders o ON o.id = p.orderid
#   JOIN order_types ot ON ot.id = o.order_type
#   JOIN order_status s ON s.id = o.order_status
#   JOIN user_data_vendor v ON v.userid = p.acceptedby
#   LEFT JOIN clients AS c ON c.id = x.clientid
# #   WHERE o.companyid = 2
# ORDER BY 1, 7;


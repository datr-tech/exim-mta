/*
 * script     1048_select_maildir_root.sql
 *
 * date       15th February 2025
 * author     J.A.Strachan
 */
/*
 * script     _select_maildir_root.sql
 *
 * purpose    Select a single, active 'maildir' from 'email_domains'
 *
 * date       15th February 2025
 * author     J.A.Strachan
 *
 * notes:     Please be aware this .sql script will be called on
 *            demand by '[PROJECT_ROOT]/test/bootstrap.sh', which, in turn,
 *            will be executed by Bashunit when running unit tests.
 */
USE email_accounts;

SELECT
  ed.maildir_root           AS maildir_root
FROM email_domains          AS ed
JOIN email_domain_statuses  AS eds
  ON ed.email_domain_status_id = eds.email_domain_status_id
WHERE
  ed.email_domain             = 'strachan.email'
  AND eds.email_domain_status = 'active';

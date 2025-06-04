--Lấy tất cả report_log
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllReportLog`()
BEGIN
    SELECT * FROM report_log;
END

--Lấy report_log bằng Id
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetReportLogById`(
    IN p_report_log_id BIGINT
)
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*) INTO v_count FROM report_log WHERE id = p_report_log_id;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lịch sử xử lý báo cáo không tồn tại.';
    END IF;

    SELECT * FROM report_log WHERE id = p_report_log_id;
END

--Cập nhật report_log
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateReportLog`(
    IN p_report_id BIGINT,
    IN p_new_status ENUM('APPROVED', 'REJECTED'),
    IN p_content TEXT,
    IN p_manager_id BIGINT
)
BEGIN
    -- Kiểm tra trạng thái hiện tại có phải là 'PENDING'
    IF NOT EXISTS (
        SELECT 1 FROM report_log
        WHERE report_id = p_report_id AND status = 'PENDING'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Chỉ được cập nhật khi trạng thái hiện tại là PENDING.';
    END IF;

    -- Kiểm tra manager_id có tồn tại và có role là 1 không
    IF NOT EXISTS (
        SELECT 1 FROM account
        WHERE id = p_manager_id AND role_id = 1
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Người duyệt không hợp lệ (phải có vai trò quản lý).';
    END IF;

    -- Cập nhật report_log
    UPDATE report_log
    SET
        status = p_new_status,
        content = p_content,
        manager_id = p_manager_id
    WHERE report_id = p_report_id;
END 
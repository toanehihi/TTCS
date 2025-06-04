--Thêm report
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertReport`(
    IN p_title VARCHAR(255),
    IN p_content TEXT,
    IN p_author_id BIGINT
)
BEGIN
    -- Kiểm tra author_id có tồn tại trong bảng account không
    IF NOT EXISTS (SELECT 1 FROM account WHERE id = p_author_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Tài khoản không tồn tại.';
    END IF;

    -- Kiểm tra role của author_id có phải là 2 không
    IF NOT EXISTS (
        SELECT 1
        FROM account
        WHERE id = p_author_id AND role_id = 2
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Tài khoản không có quyền tạo báo cáo.';
    END IF;

    -- Thêm báo cáo mới
    INSERT INTO report (title, content, author_id)
    VALUES (p_title, p_content, p_author_id);
END

--Lấy tất cả report
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllReport`()
BEGIN
    SELECT * FROM report;
END

--Lấy report qua Id
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetReportById`(
    IN p_report_id BIGINT
)
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*) INTO v_count FROM report WHERE id = p_report_id;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Báo cáo không tồn tại.';
    END IF;

    SELECT * FROM report WHERE id = p_report_id;
END

--Xóa report
CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteReport`(
    IN p_report_id BIGINT
)
BEGIN
    DECLARE v_count INT;

    -- Kiểm tra báo cáo có tồn tại không
    SELECT COUNT(*) INTO v_count
    FROM report
    WHERE id = p_report_id;

    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Báo cáo không tồn tại.';
    END IF;

    -- Kiểm tra xem có log nào không ở trạng thái PENDING không
    SELECT COUNT(*) INTO v_count
    FROM report_log
    WHERE report_id = p_report_id AND status != 'PENDING';

    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không thể xóa vì báo cáo đã được duyệt hoặc từ chối.';
    END IF;

    -- Xóa report (trigger sẽ tự động xóa report_log liên quan)
    DELETE FROM report
    WHERE id = p_report_id;
END 
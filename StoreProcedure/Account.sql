--Đổi mật khẩu
CREATE DEFINER=`root`@`localhost` PROCEDURE `ChangePassword`(
    IN p_username VARCHAR(100),
    IN p_password VARCHAR(255),
    IN p_new_password VARCHAR(255)
)
BEGIN
    DECLARE v_account_id BIGINT;
    DECLARE v_password_hashed VARCHAR(255);
    DECLARE v_new_password_hashed VARCHAR(255);

    -- Mã hóa mật khẩu cũ và mới
    SET v_password_hashed = SHA2(p_password, 256);
    SET v_new_password_hashed = SHA2(p_new_password, 256);

    -- Kiểm tra thông tin đăng nhập
    SELECT id INTO v_account_id
    FROM account
    WHERE username = p_username AND password = v_password_hashed
    LIMIT 1;

    -- Nếu không tìm thấy tài khoản
    IF v_account_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tên đăng nhập hoặc mật khẩu không đúng!';
    END IF;

    -- Cập nhật mật khẩu mới
    UPDATE account
    SET password = v_new_password_hashed
    WHERE id = v_account_id;

    SELECT 'Đổi mật khẩu thành công!' AS message;
END

--Khóa hoặc mở khóa tài khoản
CREATE DEFINER=`root`@`localhost` PROCEDURE `ChangeStatusAccount`(
    IN p_account_id BIGINT
)
BEGIN
    DECLARE v_current_status ENUM('ACTIVE', 'LOCKED');

    -- Kiểm tra tài khoản có tồn tại không
    IF NOT EXISTS (
        SELECT 1 FROM account WHERE id = p_account_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tài khoản không tồn tại!';
    END IF;

    -- Lấy status hiện tại
    SELECT status INTO v_current_status
    FROM account
    WHERE id = p_account_id;

    -- Đổi trạng thái
    UPDATE account
    SET status = CASE 
                    WHEN v_current_status = 'ACTIVE' THEN 'LOCKED'
                    ELSE 'ACTIVE'
                END
    WHERE id = p_account_id;
END

--Lấy tất cả account
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllAccount`()
BEGIN
	select * from account;
END

--Đăng nhập
CREATE DEFINER=`root`@`localhost` PROCEDURE `Login`(
    IN p_username VARCHAR(100),
    IN p_password VARCHAR(255)
)
BEGIN
    DECLARE v_password_hashed VARCHAR(255);
    DECLARE v_account_id BIGINT;
    DECLARE v_status ENUM('ACTIVE', 'LOCKED');

    -- Mã hóa mật khẩu đầu vào
    SET v_password_hashed = SHA2(p_password, 256);

    -- Lấy thông tin tài khoản
    SELECT id, status
    INTO v_account_id, v_status
    FROM account
    WHERE username = p_username AND password = v_password_hashed
    LIMIT 1;
    
  -- Phải bao thêm xử lý lỗi không tìm thấy
    IF v_account_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tên đăng nhập hoặc mật khẩu không đúng!';
    END IF;

    -- Nếu tài khoản bị khóa
    IF v_status = 'LOCKED' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tài khoản đã bị khóa, không thể đăng nhập!';
    END IF;

    -- Nếu thành công
    SELECT 'Đăng nhập thành công!' AS message;
END

--Đặt lại password của 1 tài khoản
CREATE DEFINER=`root`@`localhost` PROCEDURE `ResetPassword`(
    IN p_account_id BIGINT
)
BEGIN
    -- Kiểm tra account có tồn tại không
    IF NOT EXISTS (
        SELECT 1 FROM account WHERE id = p_account_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tài khoản không tồn tại!';
    END IF;

    -- Cập nhật mật khẩu thành SHA2('123')
    UPDATE account
    SET password = SHA2('123', 256)
    WHERE id = p_account_id;
END

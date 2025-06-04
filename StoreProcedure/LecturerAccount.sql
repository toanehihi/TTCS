--Lấy tất cả LecturerAccount
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllLecturerAccount`()
BEGIN
	select * from lecturer_account;
END

--Thêm LecturerAccount
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertLecturerAccount`(
    IN p_code VARCHAR(36),
    IN p_full_name VARCHAR(100),
    IN p_email VARCHAR(255),
    IN p_phone VARCHAR(10),
    IN p_gender BIT,
    IN p_birthday DATE,
    IN p_department_id BIGINT
)
BEGIN
    -- Thêm vào bảng lecturer_account
    INSERT INTO lecturer_account (code, full_name, email, phone, gender, birthday, department_id)
    VALUES (p_code, p_full_name, p_email, p_phone, p_gender, p_birthday, p_department_id);

        --Tạo MySQL user username = p_code, password = p_mysql_password
    SET @sql = CONCAT('CREATE USER \'', p_code, '\'@\'localhost\' IDENTIFIED BY \'', SHA2(p_code, 256), '\';');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    --Cấp quyền cho user
    SET @sql_default_role = CONCAT('SET DEFAULT ROLE `LECTURER` FOR \'', p_code, '\'@\'localhost\';');
    PREPARE stmt FROM @sql_default_role;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END 
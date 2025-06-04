--Lấy tất cả ManagerAccount
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllManagerAccount`()
BEGIN
	select * from manager_account;
END

--Thêm ManagerAccount
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertManagerAccount`(
    IN p_code VARCHAR(36),
    IN p_full_name VARCHAR(100),
    IN p_email VARCHAR(255),
    IN p_phone VARCHAR(10),
    IN p_birthday DATE,
    IN p_gender BIT
)
BEGIN
    -- Thêm vào bảng manager_account
    INSERT INTO manager_account (code, full_name, email, phone, birthday, gender)
    VALUES (p_code, p_full_name, p_email, p_phone, p_birthday, p_gender);

    --Tạo MySQL user username = p_code, password = p_mysql_password
    SET @sql = CONCAT('CREATE USER \'', p_code, '\'@\'localhost\' IDENTIFIED BY \'', SHA2(p_code, 256), '\';');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    --Cấp quyền cho user
    SET @sql_default_role = CONCAT('SET DEFAULT ROLE `MANAGER` FOR \'', p_code, '\'@\'localhost\';');
    PREPARE stmt FROM @sql_default_role;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END 
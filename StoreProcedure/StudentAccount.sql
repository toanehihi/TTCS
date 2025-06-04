--Lấy tất cả StudentAccount
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllStudentAccount`()
BEGIN
	select * from student_account;
END

--Thêm StudentAccount
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertStudentAccount`(
    IN p_code VARCHAR(36),
    IN p_full_name VARCHAR(100),
    IN p_phone VARCHAR(10),
    IN p_email VARCHAR(255),
    IN p_gender BIT,
    IN p_birthday DATE
)
BEGIN
    -- Thêm vào bảng student_account
    INSERT INTO student_account (code, full_name, phone, email, gender, birthday)
    VALUES (p_code, p_full_name, p_phone, p_email, p_gender, p_birthday);

    --Tạo MySQL user username = p_code, password = p_mysql_password
    SET @sql = CONCAT('CREATE USER \'', p_code, '\'@\'localhost\' IDENTIFIED BY \'', SHA2(p_code, 256), '\';');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    --Cấp quyền cho user
    SET @sql_default_role = CONCAT('SET DEFAULT ROLE `STUDENT` FOR \'', p_code, '\'@\'localhost\';');
    PREPARE stmt FROM @sql_default_role;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END 
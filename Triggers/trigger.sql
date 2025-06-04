--Tự động thêm thông tin vào bảng account sau khi thêm thông tin vào bảng lecturer_account
CREATE DEFINER=`root`@`localhost` TRIGGER `before_insert_lecturer_account` BEFORE INSERT ON `lecturer_account` FOR EACH ROW BEGIN
    INSERT INTO account (username, password, role_id, status, created_at)
    VALUES (
        NEW.code,
        SHA2(NEW.code, 256),
        2, -- Lecturer role
        'ACTIVE',
        CURRENT_TIMESTAMP
    );
    SET NEW.account_id = LAST_INSERT_ID();
END



--Tự động thêm thông tin vào bảng account sau khi thêm thông tin từ bảng manager_account
CREATE DEFINER=`root`@`localhost` TRIGGER `before_insert_manager_account` BEFORE INSERT ON `manager_account` FOR EACH ROW BEGIN
    -- Thêm một dòng vào account trước
    INSERT INTO account (username, password, role_id, status, created_at)
    VALUES (
        NEW.code,
        SHA2(NEW.code, 256),
        1,
        'ACTIVE',
        CURRENT_TIMESTAMP
    );

    -- Gán account_id vừa tạo vào bản ghi manager_account
    SET NEW.account_id = LAST_INSERT_ID();
END


--Tự động thêm thông tin vào bảng account sau khi thêm thông tin từ bảng student_account
CREATE DEFINER=`root`@`localhost` TRIGGER `before_insert_student_account` BEFORE INSERT ON `student_account` FOR EACH ROW BEGIN
    INSERT INTO account (username, password, role_id, status, created_at)
    VALUES (
        NEW.code,
        SHA2(NEW.code, 256),
        3, -- Student role
        'ACTIVE',
        CURRENT_TIMESTAMP
    );
    SET NEW.account_id = LAST_INSERT_ID();
END



--Tự động thêm vào report_log sau khi thêm vào report
CREATE DEFINER=`root`@`localhost` TRIGGER `after_insert_report_log` AFTER INSERT ON `report` FOR EACH ROW BEGIN
    INSERT INTO report_log (
        report_id,
        status,
        content,
        manager_id,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        'PENDING',
        NULL,
        NULL,
        NOW(),
        NULL
    );
END


--Tự động xóa report_log sau khi xóa report
CREATE DEFINER=`root`@`localhost` TRIGGER `trg_after_delete_report` AFTER DELETE ON `report` FOR EACH ROW BEGIN
    DELETE FROM report_log
    WHERE report_id = OLD.id;
END



--Trigger kiểm tra lịch học trùng, chồng chéo khi insert
CREATE TRIGGER trg_check_room_schedule_overlap
BEFORE INSERT ON schedule
FOR EACH ROW
BEGIN
  DECLARE conflict_count INT;

  SELECT COUNT(*) INTO conflict_count
  FROM schedule
  WHERE room_id = NEW.room_id
    AND semester_week_id = NEW.semester_week_id
    AND day_of_week = NEW.day_of_week
    AND (
      NEW.start_period <= start_period + total_period - 1
      AND NEW.start_period + NEW.total_period - 1 >= start_period
    );

  IF conflict_count > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phòng đã có lịch trùng thời gian.';
  END IF;
END
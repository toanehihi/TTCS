--Xóa room
CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteRoom`(
    IN room_id BIGINT
)
BEGIN
    -- Kiểm tra xem phòng có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM room WHERE id = room_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phòng không tồn tại.';
    END IF;

    -- Kiểm tra xem phòng có được sử dụng trong schedule không
    IF EXISTS (SELECT 1 FROM schedule WHERE room_id = room_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phòng đã có thông tin liên kết, không thể xóa.';
    END IF;

    -- Xóa phòng
    DELETE FROM room WHERE id = room_id;

END

--Lấy tất cả room
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAllRooms`()
BEGIN
    SELECT *
    FROM room;
END

--Lấy room qua id
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetRoomById`(
    IN room_id BIGINT
)
BEGIN
    -- Kiểm tra xem phòng có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM room WHERE id = room_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room does not exist';
    END IF;

    -- Trả về thông tin phòng theo id
    SELECT *
    FROM room
    WHERE id = room_id;
END

--Thêm room
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertRoom`(
    IN room_name VARCHAR(36),
    IN room_capacity INT,
    IN room_status ENUM('AVAILABLE', 'UNAVAILABLE', 'REPAIRING'),
    IN room_description VARCHAR(255),
    IN room_type ENUM('LECTURE_HALL', 'COMPUTER_LAB')
)
BEGIN
    -- Kiểm tra capacity > 0
    IF room_capacity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sức chứa tối đa phải lớn hơn 0,';
    END IF;

    -- Thêm phòng vào bảng room
    INSERT INTO room (name, capacity, status, description, type)
    VALUES (room_name, room_capacity, room_status, room_description, room_type);
END

--Cập nhật thông tin room
CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateRoom`(
    IN room_id BIGINT,
    IN room_name VARCHAR(36),
    IN room_capacity INT,
    IN room_status ENUM('AVAILABLE', 'UNAVAILABLE', 'REPAIRING'),
    IN room_description VARCHAR(255)
)
BEGIN

    -- Kiểm tra xem phòng có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM room WHERE id = room_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phòng không tồn tại.';
    END IF;

    -- Kiểm tra capacity > 0
    IF room_capacity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sức chứa tối đa phải lớn hơn 0.';
    END IF;

    -- Cập nhật phòng
    UPDATE room
    SET name = room_name,
        capacity = room_capacity,
        status = room_status,
        description = room_description
    WHERE id = room_id;

END
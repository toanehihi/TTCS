--Event tự động cập nhật mỗi ngày nếu schedule nào có ngày học là ngày đã qua thì sẽ tự động đổi trạng thái thành COMPLETED

DELIMITER $$

CREATE EVENT IF NOT EXISTS UpdateScheduleStatusEvent
ON SCHEDULE EVERY 1 DAY
STARTS TIMESTAMP(CURRENT_DATE + INTERVAL 1 DAY)
DO
BEGIN
    UPDATE schedule s
    JOIN semester_week w ON s.semester_week_id = w.id
    SET s.status = 'COMPLETED'
    WHERE
        s.status = 'IN_PROGRESS'
        AND DATE_ADD(w.start_date, INTERVAL s.day_of_week - 2 DAY) < CURRENT_DATE();
END$$

DELIMITER ;
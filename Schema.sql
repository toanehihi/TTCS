CREATE TABLE `role`
(
    `id`   BIGINT PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(36) UNIQUE NOT NULL
);

CREATE TABLE `account`
(
    `id`         BIGINT PRIMARY KEY AUTO_INCREMENT,
    `username`   VARCHAR(50) UNIQUE        NOT NULL,
    `password`   VARCHAR(255)              NOT NULL,
    `role_id`    BIGINT                    NOT NULL,
    `status`     ENUM ('ACTIVE', 'LOCKED') NOT NULL DEFAULT 'ACTIVE',
    `created_at` TIMESTAMP                          DEFAULT (CURRENT_TIMESTAMP)
);

CREATE TABLE `department`
(
    `id`   BIGINT PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE `major`
(
    `id`            BIGINT PRIMARY KEY AUTO_INCREMENT,
    `code`          VARCHAR(255) UNIQUE NOT NULL,
    `name`          VARCHAR(255) UNIQUE NOT NULL,
    `department_id` BIGINT              NOT NULL
);

CREATE TABLE `specialization`
(
    `id`       BIGINT PRIMARY KEY,
    `name`     VARCHAR(100) NOT NULL,
    `major_id` BIGINT       NOT NULL
);

CREATE TABLE `class`
(
    `id`                BIGINT PRIMARY KEY AUTO_INCREMENT,
    `name`              VARCHAR(50) UNIQUE               NOT NULL,
    `major_id`          BIGINT                           NOT NULL,
    `specialization_id` BIGINT,
    `class_type`        ENUM ('MAJOR', 'SPECIALIZATION') NOT NULL
);

CREATE TABLE `student_account`
(
    `account_id` BIGINT PRIMARY KEY,
    `code`       VARCHAR(36) UNIQUE  NOT NULL,
    `full_name`  VARCHAR(100)        NOT NULL,
    `phone`      VARCHAR(10) UNIQUE  NOT NULL,
    `email`      VARCHAR(255) UNIQUE NOT NULL,
    `gender`     BIT                 NOT NULL,
    `birthday`   date                NOT NULL
);

CREATE TABLE `student_on_class`
(
    `student_id` BIGINT,
    `class_id`   BIGINT,
    `status`     ENUM ('ENROLLED', 'COMPLETED', 'DROPPED') NOT NULL,
    PRIMARY KEY (`student_id`, `class_id`)
);

CREATE TABLE `lecturer_account`
(
    `account_id`    BIGINT PRIMARY KEY,
    `code`          VARCHAR(36) UNIQUE  NOT NULL,
    `full_name`     VARCHAR(100)        NOT NULL,
    `email`         VARCHAR(255) UNIQUE NOT NULL,
    `phone`         VARCHAR(10) UNIQUE  NOT NULL,
    `gender`        BIT                 NOT NULL,
    `birthday`      date                NOT NULL,
    `department_id` BIGINT              NOT NULL
);

CREATE TABLE `manager_account`
(
    `account_id` BIGINT PRIMARY KEY,
    `code`       VARCHAR(36) UNIQUE  NOT NULL,
    `full_name`  VARCHAR(100)        NOT NULL,
    `email`      VARCHAR(255) UNIQUE NOT NULL,
    `phone`      VARCHAR(10) UNIQUE  NOT NULL,
    `birthday`   date                NOT NULL,
    `gender`     BIT                 NOT NULL
);

CREATE TABLE `semester`
(
    `id`         BIGINT PRIMARY KEY AUTO_INCREMENT,
    `code`       VARCHAR(36) UNIQUE NOT NULL,
    `name`       VARCHAR(36) UNIQUE NOT NULL,
    `start_date` TIMESTAMP          NOT NULL,
    `end_date`   TIMESTAMP          NOT NULL
);

CREATE TABLE `subject`
(
    `id`                       BIGINT PRIMARY KEY AUTO_INCREMENT,
    `code`                     VARCHAR(36) UNIQUE NOT NULL,
    `name`                     VARCHAR(100)       NOT NULL,
    `total_credits`            INT                NOT NULL,
    `total_theory_periods`     INT                NOT NULL,
    `total_practice_periods`   INT                NOT NULL,
    `total_exercise_periods`   INT                NOT NULL,
    `total_self_study_periods` INT                NOT NULL
);

CREATE TABLE `course`
(
    `id`             BIGINT PRIMARY KEY AUTO_INCREMENT,
    `subject_id`     BIGINT NOT NULL,
    `class_id`       BIGINT NOT NULL,
    `semester_id`    BIGINT NOT NULL,
    `group_number`   INT    NOT NULL,
    `total_students` INT    NOT NULL
);

CREATE TABLE `lecturer_on_course`
(
    `course_id`   BIGINT,
    `lecturer_id` BIGINT,
    PRIMARY KEY (`course_id`, `lecturer_id`)
);

CREATE TABLE `course_section`
(
    `id`                        BIGINT PRIMARY KEY AUTO_INCREMENT,
    `course_id`                 BIGINT NOT NULL,
    `section_number`            INT    NOT NULL,
    `total_students_in_section` INT    NOT NULL
);

CREATE TABLE `room`
(
    `id`           BIGINT PRIMARY KEY AUTO_INCREMENT,
    `name`         VARCHAR(36) UNIQUE                             NOT NULL,
    `capacity`     INT                                            NOT NULL,
    `status`       ENUM ('AVAILABLE', 'UNAVAILABLE', 'REPAIRING') NOT NULL DEFAULT 'AVAILABLE',
    `description`  VARCHAR(255)                                   NOT NULL,
    `last_updated` DATETIME                                       NOT NULL DEFAULT (CURRENT_TIMESTAMP),
    `type`         ENUM ('LECTURE_HALL', 'COMPUTER_LAB') NOT NULL
);

CREATE TABLE `semester_week`
(
    `id`          BIGINT PRIMARY KEY AUTO_INCREMENT,
    `name`        VARCHAR(100) NOT NULL,
    `start_date`  TIMESTAMP    NOT NULL,
    `end_date`    TIMESTAMP    NOT NULL,
    `semester_id` BIGINT       NOT NULL
);

CREATE TABLE `schedule`
(
    `id`                BIGINT PRIMARY KEY AUTO_INCREMENT,
    `course_id`         BIGINT,
    `course_section_id` BIGINT,
    `room_id`           BIGINT                                         NOT NULL,
    `day_of_week`       TINYINT                                        NOT NULL,
    `lecturer_id`       BIGINT                                         NOT NULL,
    `start_period`      INT                                            NOT NULL,
    `total_period`      INT                                            NOT NULL,
    `semester_week_id`  BIGINT                                         NOT NULL,
    `status`            ENUM ('IN_PROGRESS', 'COMPLETED', 'CANCELLED') NOT NULL,
    `type`              ENUM ('THEORY', 'PRACTICE')                    NOT NULL
);



#REPORT
#==================================================#
CREATE TABLE report
(
    id        BIGINT PRIMARY KEY AUTO_INCREMENT,
    title     VARCHAR(255) NOT NULL,
    content   TEXT         NOT NULL,
    author_id BIGINT       NOT NULL,
    FOREIGN KEY (author_id) REFERENCES account (id)
);

CREATE TABLE report_log
(
    report_id  BIGINT PRIMARY KEY,
    status     ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED') NOT NULL,
    content    TEXT,
    manager_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (report_id) REFERENCES report (id) ON DELETE CASCADE,
    FOREIGN KEY (manager_id) REFERENCES manager_account (account_id)
);


#==================================================#
CREATE TABLE student_on_course
(
    student_id BIGINT,
    course_id  BIGINT,
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES student_account (account_id),
    FOREIGN KEY (course_id) REFERENCES course (id)
);
#==================================================#

ALTER TABLE `account`
    ADD FOREIGN KEY (`role_id`) REFERENCES `role` (`id`);

ALTER TABLE `major`
    ADD FOREIGN KEY (`department_id`) REFERENCES `department` (`id`);

ALTER TABLE `specialization`
    ADD FOREIGN KEY (`major_id`) REFERENCES `major` (`id`);

ALTER TABLE `class`
    ADD FOREIGN KEY (`major_id`) REFERENCES `major` (`id`);

ALTER TABLE `class`
    ADD FOREIGN KEY (`specialization_id`) REFERENCES `specialization` (`id`);

ALTER TABLE `student_account`
    ADD FOREIGN KEY (`account_id`) REFERENCES `account` (`id`) ON DELETE CASCADE;

ALTER TABLE `student_on_class`
    ADD FOREIGN KEY (`student_id`) REFERENCES `student_account` (`account_id`) ON DELETE CASCADE;

ALTER TABLE `student_on_class`
    ADD FOREIGN KEY (`class_id`) REFERENCES `class` (`id`);

ALTER TABLE `lecturer_account`
    ADD FOREIGN KEY (`account_id`) REFERENCES `account` (`id`) ON DELETE CASCADE;

ALTER TABLE `lecturer_account`
    ADD FOREIGN KEY (`department_id`) REFERENCES `department` (`id`) ON DELETE CASCADE;

ALTER TABLE `manager_account`
    ADD FOREIGN KEY (`account_id`) REFERENCES `account` (`id`) ON DELETE CASCADE;

ALTER TABLE `course`
    ADD FOREIGN KEY (`subject_id`) REFERENCES `subject` (`id`);

ALTER TABLE `course`
    ADD FOREIGN KEY (`class_id`) REFERENCES `class` (`id`);

ALTER TABLE `course`
    ADD FOREIGN KEY (`semester_id`) REFERENCES `semester` (`id`);

ALTER TABLE `lecturer_on_course`
    ADD FOREIGN KEY (`course_id`) REFERENCES `course` (`id`) ON DELETE CASCADE;

ALTER TABLE `lecturer_on_course`
    ADD FOREIGN KEY (`lecturer_id`) REFERENCES `lecturer_account` (`account_id`);

ALTER TABLE `course_section`
    ADD FOREIGN KEY (`course_id`) REFERENCES `course` (`id`) ON DELETE CASCADE;

ALTER TABLE `semester_week`
    ADD FOREIGN KEY (`semester_id`) REFERENCES `semester` (`id`) ON DELETE CASCADE;

ALTER TABLE `schedule`
    ADD FOREIGN KEY (`course_id`) REFERENCES `course` (`id`) ON DELETE CASCADE;

ALTER TABLE `schedule`
    ADD FOREIGN KEY (`course_section_id`) REFERENCES `course_section` (`id`);

ALTER TABLE `schedule`
    ADD FOREIGN KEY (`room_id`) REFERENCES `room` (`id`);

ALTER TABLE `schedule`
    ADD FOREIGN KEY (`lecturer_id`) REFERENCES `lecturer_account` (`account_id`);

ALTER TABLE `schedule`
    ADD FOREIGN KEY (`semester_week_id`) REFERENCES `semester_week` (`id`);


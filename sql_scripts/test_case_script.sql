-- TEST01 INSERT USER 
SELECT * FROM user;
INSERT INTO User (
	User_ID, User_name, User_nickname, User_password, User_email, User_phoneNum, User_address, User_birth,
	User_sign_up_date, User_coupon, Dealer_company, Dealer_region, Dealer_grade, User_type, User_blacklist,
	Restriction_date, Restriction_end_date, Login_fail_stack, Report_issue_stack, Login_restriction_check,
	User_withdraw_check, User_withdraw_date 
)
VALUES 
(
 NULL, 
 'test','test_nick','test_passwd','test@gmail.com','010-5678-1234','서울','2023-1-1 00:00:00', NOW(),
  NULL,	'test_company',	 'test_region',  1,	1,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL, 0,	NULL 
);
SELECT * FROM user;

-- TEST02 Update user 
SELECT user_withdraw_check, user_withdraw_date FROM user WHERE user_id = 4; 
update User set User_withdraw_check=1, User_withdraw_date=NOW() WHERE user_id = 4;
SELECT user_withdraw_check, user_withdraw_date FROM user WHERE user_id = 4;

-- TEST03 Login_log insert
SELECT * FROM login_log;
INSERT INTO Login_log (Success_check, Attempt_date, Attempt_time, Attempt_region, User_ID) Values (1, NOW(), NOW(), '서울', 1);
SELECT * FROM login_log;

-- TEST04 Trigger ( Login fail -> fail stack update ) 
SHOW * FROM login_log ;
SHOW login_fail_stack FROM user; 

DELIMITER //

CREATE OR REPLACE TRIGGER LOGIN_FAIL_TR
    AFTER INSERT 
    ON Login_log
    FOR EACH ROW
BEGIN 
    IF NEW.Success_check = 0 THEN
        UPDATE USER
        SET Login_fail_stack = Login_fail_stack + 1
        WHERE user_id = New.user_id; 
    END IF;
END//

DELIMITER ;

SHOW * FROM login_log ;
SHOW login_fail_stack FROM user; 

-- TEST05 update user's password
SELECT user_password FROM User WHERE user_id = 5;  
update User set user_password='updatetest' WHERE User_id = 5;
SELECT user_password FROM User WHERE user_id = 5;  

-- TEST06 update user's nickname, email, phoneNum, address
SELECT user_nickname FROM user WHERE user_id = 5;
update User set user_nickname='testnickname', user_email='updatetest@gmail.com', user_phonenum='010-8888-8888', user_address='광주' WHERE User_id = 5;
SELECT user_nickname FROM user WHERE user_id = 5;

-- TEST07 JOIN test ( user table - review table)
SELECT b.user_name, a.review_grade, a.review_contents 
  FROM review a
  JOIN User b ON a.dealer_id = b.user_id
 WHERE a.dealer_id = 2;
 
-- TEST08 TRANSACTION test 
START TRANSACTION;

-- Example: Insert new data at Car table 
INSERT INTO Car (
	  Car_ID, Car_field, Car_model, Car_year, Car_mileage, Car_condition, 
	  Car_transmission, Car_oiltype, Car_engine, Car_fuel_efficiency,
	  Accident_check, Inundation_check, Selling_price, Picture_URL, 
	  Picture_origin, Picture_rename, Model_ID, Insepction_record_URL
)
VALUES 
(
	 99, 'Hyundai', 'Sonata', 2019, 50000, 'Good', 'Automatic', 
	 'Gasoline', '2.0L', 15, 0, 0, 20000, '/images/sonata.jpg', 
	 'sonata_original.jpg', 'sonata_rename.jpg', 'M2', '/inspection/M2'
);

-- Ownership_history insert
INSERT INTO Ownership_history (
    Previous_Owner, Current_Owner, Ownership_start, Ownership_end, 
		Reason_transfer, Descript_transfer, Car_ID
)
VALUES 
(
    '이재원', '이준형', '2021-04-03 09:00:00', '2023-03-15 17:30:00',
    '직장 지역이동에 의한 판매', '차량 상태 우수, 주행거리 낮음', 99
);

-- Accident_History insert
SELECT * FROM Accident_History;
INSERT INTO Accident_History (
    Accident_damage_degree, Accident_date, Insurance_claim_check,
    Accident_code, Car_ID
)
VALUES 
(
    2, '2022-05-20 16:00:00',  1,
    'FACD001', 99
);

-- Inundation insert
SELECT * from Inundation;
INSERT INTO Inundation (
    Inundation_degree, Inundation_date, Accident_code, Car_ID
)
VALUES 
(
    3, '2022-07-10 10:15:00', 'DACD001', 99
);

-- Transaction 종료
COMMIT;

-- TC009 Trigger test
DELIMITER //
CREATE TRIGGER AfterReportUpdate
BEFORE UPDATE ON User
FOR EACH ROW
BEGIN
  -- report_issue_stack = 5, 10, 15,... 25 -> add black list 
  IF NEW.Report_issue_stack % 5 = 0 AND NEW.Report_issue_stack < 30 THEN
    SET NEW.User_blacklist = 1;
    SET NEW.Restriction_date = NOW();
    SET NEW.Restriction_end_date = DATE_ADD(NOW(), INTERVAL NEW.Report_issue_stack DAY);
  END IF;

  -- report_issue_stack = 30 -> withdraw update
  IF NEW.Report_issue_stack >= 30 THEN
 		SET NEW.User_withdraw_check = 1;
 		SET NEW.User_withdraw_date = NOW();
  END IF;
END;
//
DELIMITER ;

-- TEST010 Multi Join test ( Ownership_history - Car - Model ) 
SELECT Car.Car_ID, Car.Car_model, Model.Model_name, Ownership_history.Current_Owner
FROM Car
JOIN Model ON Car.Model_ID = Model.Model_ID
JOIN Ownership_history ON Car.Car_ID = Ownership_history.Car_ID;
SELECT * FROM CarOwnershipView; 


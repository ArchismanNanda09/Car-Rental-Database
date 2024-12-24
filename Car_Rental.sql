--Archisman Nanda
--This procedure inputs new agency being opened by the rental company when we provide with the location
--15/12/2024
create or replace PROCEDURE input_agency(p_agency_loc VARCHAR2)
  IS
  p_agency_id varchar2(20);
  BEGIN 
    IF p_agency_loc NOT IN ('Bangalore','Chennai','Hyderabad')  --Check if the location is one of these 3 location
    THEN
      RAISE_APPLICATION_ERROR(-20001,'Invalid Location');
    END IF;
    SELECT 'A'||LPAD(agency_id_primary.NEXTVAL,3,0)  --using the sequence as the primary key so the user does not have to input it
    INTO p_agency_id
    FROM dual;
    INSERT INTO Agency(agency_id,Agency_loc)
    VALUES('A'||LPAD(agency_id_primary.NEXTVAL,3,0),p_agency_loc);
    COMMIT;
  END;
  
--Archisman Nanda
--This procedure inputs when a new customer is registered, checking if the customer is above the age of 18.
--And prevents him from registering with more than one agency
--15/12/2024
  create or replace PROCEDURE input_customer(p_customer_name         varchar2,
                                             p_address               varchar2,
                                             p_contact_number        varchar2,
                                             p_email                 varchar2,
                                             p_agency_id             varchar2,
                                             p_date_of_registration  DATE,
                                             p_age                   NUMBER)
    AS
      p_customer_id VARCHAR2(20);
      v_one_agency  VARCHAR2(20);
    BEGIN
      IF p_age<18 THEN
        RAISE_APPLICATION_ERROR(-20002,'Customer must be 18 years of age');    --Checking if the customer is above legal age
      END IF;
       IF NOT REGEXP_LIKE(p_agency_id,'^A(0[0-9][1-9]|0[1-9][0-9]|100)$') THEN    --checking the format of the ID
          RAISE_APPLICATION_ERROR(-20001,'Wrong agency ID');
      END IF;     
       SELECT agency_id
    INTO v_one_agency
    FROM customer_master
    WHERE contact_number = p_contact_number;

    IF v_one_agency IS NOT NULL THEN
      RAISE_APPLICATION_ERROR(-20004, 'Customer is already registered with another agency');   --checking if the customer is registered to more than one agency
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- No existing customer found, proceed with registration
      NULL;
      SELECT 'C'||LPAD(customer_id_primary.NEXTVAL,3,0)   --using the sequence as the primary key so the user does not have to input it
      into p_customer_id
      FROM dual;
      INSERT INTO customer_master(customer_id,customer_name,address,contact_number,email_address,agency_id,Date_of_Registration,age)
      VALUES('C'||LPAD(customer_id_primary.NEXTVAL,3,0),p_customer_name,p_address,p_contact_number,p_email,p_agency_id,p_date_of_registration,p_age);  
      COMMIT;   
    END;
--Archisman Nanda
--This procedure inputs any new vehicle being added to the car roster, with cars more than 10 years old marked as dangerous
--15/12/2024
    create or replace PROCEDURE input_vehicles(p_car_model varchar2,p_manufacturer varchar2,p_year_of_manufacture NUMBER, p_fuel_type varchar2,
                                           p_seating_capacity NUMBER, p_rent_per_day NUMBER, p_vehicle_status VARCHAR2) AS
  p_car_id VARCHAR2(20);
  v_status VARCHAR2(30);
  p_current_year NUMBER(4);
  v_rent NUMBER(10,2);       
  BEGIN
    IF NOT REGEXP_LIKE(p_car_id,'^V(0[0-9][1-9]|0[1-9][0-9]|100)$') THEN --To check the format of the ID
      RAISE_APPLICATION_ERROR(-20003,'Wrong vehicle ID');
    END IF;
     
    SELECT EXTRACT(YEAR FROM SYSDATE)
    INTO p_current_year
    FROM dual;
      IF p_year_of_manufacture>p_current_year THEN   --Manufacture year cannot exceed the current year
        RAISE_APPLICATION_ERROR(-20003,'Year of manufacture cannot exceed this year');
      ELSIF p_year_of_manufacture<(p_current_year-15) THEN           
        RAISE_APPLICATION_ERROR(-20004,'The car cannot be more than 15 years old');
      END IF;
      IF (p_current_year-p_year_of_manufacture)>10 AND p_vehicle_status NOT IN ('Rented','Getting Serviced') THEN   --This checks if the car is more than 10 years old
        v_status := 'Dangerous';
      ELSE 
        v_status :=p_vehicle_status;
      END IF;
      IF v_status NOT IN ('Available','Rented','Dangerous','Getting Serviced') THEN
        RAISE_APPLICATION_ERROR(-20005,'This vehicle status is invalid');
      END IF;
      IF p_fuel_type NOT IN ('Petrol','Diesel','Electric','Hybrid') THEN
        RAISE_APPLICATION_ERROR(-20006,'There can be no other tranmission type');
      END IF;
      IF p_year_of_manufacture<2016 THEN    --Electric cars were not launced before 2016 in India
        IF p_fuel_type = 'Electric' THEN
          RAISE_APPLICATION_ERROR(-20007,'Electric cars were not launched yet');
        END IF;
      ELSIF p_year_of_manufacture<2008 THEN   --Hybrid cars were not launched  before 2008
        IF p_fuel_type ='Hybrid' THEN
          RAISE_APPLICATION_ERROR(-20008,'Hybrid cars were not launched yet');
        END IF;
      END IF;
      IF p_seating_capacity>7 THEN   --Heavy vehicles are not available
        RAISE_APPLICATION_ERROR(-20009,'No four wheeled-vehicle is this large');
      END IF;
    SELECT 'V'||LPAD(car_id_primary.NEXTVAL,3,0)  --using the sequence as the primary key so the user does not have to input it
    INTO p_car_id
    FROM dual;  
      INSERT INTO Vehicles(car_id,car_model,manufacturer,year_of_manufacture,fuel_type,seating_capacity,rent_per_day,status_of_the_car)
      VALUES('V'||LPAD(car_id_primary.NEXTVAL,3,0),p_car_model,p_manufacturer,p_year_of_manufacture,p_fuel_type,p_seating_capacity,p_rent_per_day,v_status);
         EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
      RAISE; 
      COMMIT;
      
  END;
--Archisman Nanda
--This procedure inputsinsurance details of the new car added.
--Note:- Do this immediately after a new car is added
--15/12/2024  
  create or replace PROCEDURE input_insurance(p_car_id VARCHAR2)
  AS
    v_car_id         NUMBER(10);
    v_status         VARCHAR2(25);
    v_insurance_id  VARCHAR2(20);
    v_probability   NUMBER;
    v_amount        NUMBER;
    v_rent          NUMBER;
    v_car_age       NUMBER;
    car_exists      NUMBER;
    BEGIN
       Select COUNT(*) INTO v_car_id from Vehicles 
       WHERE Car_Id=p_car_id;
       IF v_car_id=0 THEN
          RAISE_APPLICATION_ERROR(-20003,'Wrong vehicle ID');
        END IF;
        SELECT COUNT(*) into car_exists 
        FROM insurance where car_id=p_car_id;
        IF car_exists > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Insurance record already exists for this car ID');
    END IF;
      Select CASE
              WHEN status_of_the_car = 'Dangerous'  --This assigns a random value between 0.55 and 0.92 to the insurance probability
              THEN TRUNC(DBMS_RANDOM.VALUE(0.55,0.92),2)  --This only gets assigned to the cars older than 10 years
            ELSE TRUNC(DBMS_RANDOM.VALUE(0.1,0.54),2)  --All other vehicles have insurance probability between 0.1 and 0.54
           END INTO v_probability
            FROM Vehicles
            WHERE car_id=p_car_id;
      SELECT status_of_the_car 
      INTO v_status 
      FROM Vehicles 
      WHERE car_id=p_car_id;
      IF v_status = 'Cancelled' OR v_status='Rented' THEN 
        RAISE_APPLICATION_ERROR(-20001,'Only available cars can have an insurance plan');
      END IF;
      Select rent_per_day INTO v_rent --taking the rent_per_day of the specified vehicle
      FROM Vehicles
      where p_car_id=car_id;
      Select (EXTRACT(YEAR FROM SYSDATE)-year_of_manufacture) INTO v_car_age FROM Vehicles where car_id=p_car_id; --year of manufacture of specified vehicle
      
      v_amount := TRUNC(((v_rent*100)/v_probability)*(1+(1+(v_car_age/10))),2); --Formula for calculating the insured amount
      
      Select 'I'||LPAD(insurance_id_primary.NEXTVAL,3,0) --using the sequence as the primary key so the user does not have to input it
      into v_insurance_id
      FROM dual;
    
     
      INSERT INTO Insurance(insurance_id,car_id,insurance_probability,insured_amount)
      VALUES('I'||LPAD(insurance_id_primary.NEXTVAL,3,0),p_car_id,v_probability,v_amount);
         EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
      RAISE;
      COMMIT;
    END;
--Archisman Nanda
--This procedure inputs rental transaction, if need to be done manually for any special circumstances
--15/12/2024    
    create or replace PROCEDURE input_rentals(
  p_agency_id    VARCHAR2, 
  p_customer_id  VARCHAR2,
  p_car_id       VARCHAR2,
  p_rent_strt    DATE,
  p_rent_ret     DATE,
  p_actual       DATE,
  p_rent         NUMBER,
  p_status       VARCHAR2
) AS
  v_rent_id               VARCHAR2(20);
  v_return                DATE;
  v_rent                  NUMBER(10,2);
  v_status                VARCHAR2(25);
  v_registration_date     DATE;
  v_rent_per_day          NUMBER(10,2);
  rcount                  NUMBER;
BEGIN
  BEGIN
    IF NOT REGEXP_LIKE(p_agency_id,'^A(0[0-9][1-9]|0[1-9][0-9]|100)$') THEN --To check the format of the ID
      RAISE_APPLICATION_ERROR(-20001,'Wrong agency ID');
    END IF;
    IF NOT REGEXP_LIKE(p_customer_id,'^C(0[0-9][1-9]|0[1-9][0-9]|100)$') THEN --To check the format of the ID
      RAISE_APPLICATION_ERROR(-20002,'Wrong customer ID');
    END IF;
    IF NOT REGEXP_LIKE(p_car_id,'^V(0[0-9][1-9]|0[1-9][0-9]|100)$') THEN --To check the format of the ID
      RAISE_APPLICATION_ERROR(-20003,'Wrong vehicle ID');
    END IF;

    -- Check customer registration date
    BEGIN
      SELECT date_of_registration
      INTO v_registration_date
      FROM Customer_Master
      WHERE customer_id = p_customer_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Customer ID ' || p_customer_id || ' not found');
    END;
     SELECT COUNT(*) INTO rcount FROM Rentals 
  where customer_id = p_customer_id  --for the customr who availed the car
  AND Payment_Status != 'Cancelled'  --If cancelled it follows the norm for rebooking a rental so it is allowed
  AND (rent_strt_date <= p_rent_ret)  
  AND (rent_ret_date >= p_rent_strt); --If these conditions satisfy that means the rental duration overlaps and thus triggering an error
  
  IF rcount>0 THEN
    RAISE_APPLICATION_ERROR(-20001,'Customer can only avail 1 rental at a time');
   END IF;
     

    IF p_rent_strt < v_registration_date THEN
      RAISE_APPLICATION_ERROR(-20002,'User must be registered first');
    END IF;

    -- Set v_return based on p_actual and p_rent_ret
    IF p_actual IS NOT NULL THEN
      v_return := p_actual;
    ELSE
      v_return := p_rent_ret;
    END IF;

    -- Check rent per day
    BEGIN
      SELECT rent_per_day
      INTO v_rent_per_day
      FROM Vehicles
      WHERE car_id = p_car_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20004, 'Car ID ' || p_car_id || ' not found');
    END;

    v_rent := (v_rent_per_day * (v_return - p_rent_strt)); --the default rent of the car

    -- Determine v_status
    IF p_rent_strt = p_rent_ret AND p_actual IS NULL THEN
      v_status := 'Cancelled';
      v_rent := 0;
    ELSIF p_rent_strt < p_rent_ret AND p_actual IS NULL THEN
      v_status := 'To be paid';
    ELSE
      v_status := p_status;
    END IF;

   
    -- Generate rental ID
    SELECT 'R' || LPAD(rental_id_primary.NEXTVAL, 3, 0) --using the sequence as the primary key so the user does not have to input it
    INTO v_rent_id
    FROM dual;

    -- Insert rental record
    INSERT INTO RENTALS(
      rent_id, agency_id, customer_id, car_id, rent_strt_date, rent_ret_date, actual_return_date, rent, payment_status
    ) VALUES (
      'R' || LPAD(rental_id_primary.NEXTVAL, 3, 0), p_agency_id, p_customer_id, p_car_id, p_rent_strt, v_return, p_actual, v_rent, v_status);
COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
      RAISE;
 END;
 
END;
--Archisman Nanda
--This procedure enables you to rent a car, if 'availablle' or 'dangerous' changing the vehcile status to 'Rented'
--This automatically inputs the rental transaction details to the rentals table, making the payment status to 'To be paid'
--It checks whether the customer is renting more than one rental, and if the rental period does not exceed more than 90 days
--16/12/2024
create or replace PROCEDURE rent_car(
  p_agency_id    VARCHAR2, 
  p_customer_id  VARCHAR2,
  p_car_id       VARCHAR2,
  p_rent_strt    DATE,
  p_rent_ret     DATE
) AS
v_rent_id   VARCHAR2(20);
  v_car_status VARCHAR2(25);
  v_rent_per_day NUMBER;
  v_rent NUMBER;
  rcount NUMBER;
BEGIN
  IF NOT REGEXP_LIKE(p_agency_id,'^A(0[0-9][1-9]|0[1-9][0-9]|100)$') THEN --To check the format of the ID
      RAISE_APPLICATION_ERROR(-20001,'Wrong agency ID');
    END IF;
    IF NOT REGEXP_LIKE(p_customer_id,'^C(0[0-9][1-9]|0[1-9][0-9]|100)$') THEN --To check the format of the ID
      RAISE_APPLICATION_ERROR(-20002,'Wrong customer ID');
    END IF;
    IF NOT REGEXP_LIKE(p_car_id,'^V(0[0-9][1-9]|0[1-9][0-9]|100)$') THEN --To check the format of the ID
      RAISE_APPLICATION_ERROR(-20003,'Wrong vehicle ID');
    END IF;
  -- Check if the car is available or dangerous
  SELECT status_of_the_car, rent_per_day
  INTO v_car_status, v_rent_per_day
  FROM Vehicles
  WHERE car_id = p_car_id;

  IF v_car_status NOT IN ('Available', 'Dangerous') THEN
    RAISE_APPLICATION_ERROR(-20001, 'Car is not available for rent');
  END IF;

  -- Check if the rental period exceeds 90 days
  IF p_rent_ret - p_rent_strt > 90 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Rental period cannot exceed 90 days');
  END IF;
 -- Check if a customer is renting more than one rental
   SELECT COUNT(*) INTO rcount FROM Rentals 
  where customer_id = p_customer_id  --for the customr who availed the car
  AND Payment_Status != 'Cancelled'  --If cancelled it follows the norm for rebooking a rental so it is allowed
  AND (rent_strt_date <= p_rent_ret)  
  AND (rent_ret_date >= p_rent_strt); --If these conditions satisfy that means the rental duration overlaps and thus triggering an error
  
  IF rcount>0 THEN
    RAISE_APPLICATION_ERROR(-20001,'Customer can only avail 1 rental at a time');
   END IF;
     
  -- Calculate the total rent
  v_rent := v_rent_per_day * (p_rent_ret - p_rent_strt);

 
 

  -- Generate rental ID
 
  BEGIN
    SELECT 'R' || LPAD(rental_id_primary.NEXTVAL, 3, 0) --using the sequence as the primary key
    INTO v_rent_id
    FROM dual;

    -- Insert rental record
    INSERT INTO Rentals(
      rent_id, agency_id, customer_id, car_id, rent_strt_date, rent_ret_date, actual_return_date, rent, payment_status
    ) VALUES (
      v_rent_id, p_agency_id, p_customer_id, p_car_id, p_rent_strt, p_rent_ret, NULL, v_rent, 'To be paid'); --Insert null as the car is not reurned yet, and 'To be paid status in rnetals table'
  END;
   -- Update car status to 'Rented'
  UPDATE Vehicles
  SET status_of_the_car = 'Rented'
  WHERE car_id = p_car_id;
  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Car status updated to Rented and rental details inserted.');
END;
--Archisman Nanda
--This procedure enables us to return the car to the company, filling the actual_return_date in the rentals table
--It fires two triggers, to send the car for Maintanance, and filling the total final payments table that the customer has to pay
--16/12/2024
create or replace PROCEDURE return_vehicle(p_car_id VARCHAR2,p_actual DATE)
    AS
      v_rental_exists NUMBER;
      v_car_exists    NUMBER;
   BEGIN
    IF NOT REGEXP_LIKE(p_car_id,'^V(0[0-9][1-9]|0[1-9][0-9]|100)$') THEN --To check the format of the ID
      RAISE_APPLICATION_ERROR(-20003,'Wrong vehicle ID');
    END IF;
    -- Check if the car exists in the Vehicles table
    SELECT COUNT(*)
    INTO v_car_exists
    FROM Vehicles
    WHERE car_id = p_car_id;
    
    IF v_car_exists = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'Car ID ' || p_car_id || ' does not exist');
    END IF;

    -- Check if there is a valid rental record
    SELECT COUNT(*)
    INTO v_rental_exists
    FROM Rentals
    WHERE car_id = p_car_id AND actual_return_date IS NULL AND payment_status = 'To be paid';
    
    IF v_rental_exists = 0 THEN
      RAISE_APPLICATION_ERROR(-20001, 'Invalid car return for car ID ' || p_car_id);
    END IF;

    -- Update the rental record
    UPDATE Rentals
    SET actual_return_date = p_actual, payment_status = 'Paid'
    WHERE car_id = p_car_id AND actual_return_date IS NULL AND payment_status = 'To be paid';
   --Update the Vehicles table
   COMMIT;
  
    UPDATE Vehicles
    SET status_of_the_car = 'Getting Serviced' --Car is to be sent for servicing
    WHERE car_id = p_car_id;
    COMMIT;

  DBMS_OUTPUT.PUT_LINE('Car or cars are returned');
  END;
--Archisman Nanda
--This trigger inputs the payment table as soon as the actual return date is filled i.e the car is returned
--16/12/2024  
  create or replace TRIGGER POPULATE_PAYMENT_ON_RETURN
AFTER UPDATE OF actual_return_date ON Rentals
FOR EACH ROW
WHEN (NEW.actual_return_date IS NOT NULL)
DECLARE
  v_mod_id VARCHAR2(20);
  v_insurance_probability NUMBER;
  v_discount NUMBER(5,2) := 0;
  v_fine NUMBER(10,2) := 0;
  v_total_paid NUMBER(10,2);
  v_days_overdue NUMBER;
  v_rent_per_day NUMBER(10,2);
  v_payment_id VARCHAR2(10);
BEGIN
  -- Debug message
  DBMS_OUTPUT.PUT_LINE('Trigger started');

  -- Get the insurance probability from the Insurance table
  BEGIN
    SELECT insurance_probability
    INTO v_insurance_probability
    FROM Insurance
    WHERE car_id = :NEW.car_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('No insurance record found for car_id: ' || :NEW.car_id);
      RAISE;
  END;

  -- Calculate discount
  IF v_insurance_probability >= 0.55 THEN  --The cars which are more than 10 years old have 40% discount
      v_discount := 0.40 * :NEW.rent;
  ELSE
    v_discount :=0.05* :NEW.rent;  --While all other cars have 5% discount
  END IF;
 
    -- Calculate fine if the actual return date is later than the rent return date
    IF :NEW.actual_return_date > :NEW.rent_ret_date THEN
      v_days_overdue := :NEW.actual_return_date - :NEW.rent_ret_date;    
      BEGIN
        SELECT rent_per_day
        INTO v_rent_per_day
        FROM Vehicles
        WHERE car_id = :NEW.car_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          DBMS_OUTPUT.PUT_LINE('No vehicle record found for car_id: ' || :NEW.car_id);
          RAISE;
      END;      
      v_fine := v_days_overdue * v_rent_per_day * 1.60;  --Fine is 60% of the rent per day applied on the due days   
    END IF;
    

    -- Calculate total paid
    v_total_paid := :NEW.rent - v_discount + v_fine;
 
  SELECT mod_id into v_mod_id  --This is the mode of payment made 
  FROM (Select mod_id from MOD_PAY
        ORDER BY DBMS_RANDOM.VALUE)
        WHERE rownum<=1;

               
  
      

  -- Generate payment ID
  BEGIN
    SELECT 'P' || LPAD(payment_id_primary.NEXTVAL, 3, '0')
    INTO v_payment_id
    FROM dual;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error generating payment ID');
      RAISE;
      
  END;

  -- Insert into Payment table
  BEGIN
    INSERT INTO Payment (Rent_id, Payment_id, MOD_ID, Discount, Fine, Total_Paid)
    VALUES (:NEW.rent_id, v_payment_id,v_mod_id, v_discount, v_fine, v_total_paid);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error inserting into Payment table');
      RAISE;
      COMMIT;
  END;

  -- Debug message
  DBMS_OUTPUT.PUT_LINE('Trigger completed successfully');
END;


--create or replace TRIGGER update_vehicle_status
--AFTER UPDATE OF actual_return_date
--ON Rentals
--FOR EACH ROW
--WHEN (NEW.actual_return_date IS NOT NULL AND OLD.actual_return_date IS NULL AND OLD.payment_status = 'To be paid')
--BEGIN
--    -- Update the status of the vehicle to 'Getting Serviced'
--    UPDATE Vehicles
--    SET status_of_the_car = 'Getting Serviced'
--    WHERE car_id = :NEW.car_id;
--END;


--Archisman Nanda
--This procedure retreives the rental details which takes the agency id and the month as input
--16/12/2024
create or replace PROCEDURE get_rental_details(
    p_agency_id in Varchar2,
    p_month IN VARCHAR2
)
AS

BEGIN
   IF NOT REGEXP_LIKE(p_agency_id,'^A(0[0-9][1-9]|0[1-9][0-9]|100)$') THEN --To check the format of the ID
      RAISE_APPLICATION_ERROR(-20001,'Wrong agency ID');
    END IF;
  
  FOR i IN
      (SELECT 
        r.rent_id,
        r.customer_id,
        c.customer_name,
        r.agency_id,
        r.rent_strt_date
    FROM 
        rentals r
    JOIN
        customer_master c ON c.customer_id=r.customer_id
    WHERE 
        r.agency_id=p_agency_id
        AND TO_CHAR(r.rent_strt_date,'FMMonth')=INITCAP(p_month)) --FM is a format model, it removes any spaces that oracle may have added to the month name
    LOOP
      DBMS_OUTPUT.PUT_LINE('Rental ID: '||i.rent_id);
      DBMS_OUTPUT.PUT_LINE('Customer ID: '||i.customer_id);
      DBMS_OUTPUT.PUT_LINE('Customer Name: '||i.customer_name);
      DBMS_OUTPUT.PUT_LINE('Agency ID: '||i.agency_id);
      DBMS_OUTPUT.PUT_LINE('Start Date: '||TO_CHAR(i.rent_strt_date,'DD-MM-YYYY'));
    END LOOP;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No rentals found for the agency'||p_agency_id||'in the month of '||p_month||' .');
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An unexpected error has occured');
END;
exec get_rental_details('A002','September');

--Archisman Nanda
--This procedure retreives the payment details of a particular rental id
--16/12/2024
create or replace PROCEDURE get_payment_details(
  p_rent_id IN VARCHAR2
) AS
  v_mod_id VARCHAR2(10);
  v_discount NUMBER(5,2);
  v_fine NUMBER(10,2);
  v_total_paid NUMBER(10,2);
 BEGIN
  -- Retrieve payment details
  BEGIN
     IF NOT REGEXP_LIKE(p_rent_id,'^R(0[0-9][1-9]|0[1-9][0-9]|100)$') THEN --To check the format of the ID
      RAISE_APPLICATION_ERROR(-20001,'Wrong rent ID');
    END IF;
    SELECT Mod_id,Discount, Fine, Total_Paid
    INTO v_mod_id,v_discount, v_fine, v_total_paid
    FROM Payment
    WHERE Rent_id = p_rent_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('No payment record found for rent_id: ' || p_rent_id);
      RETURN;
  END;

  -- Output payment details
  DBMS_OUTPUT.PUT_LINE('Payment Details for Rent ID: ' || p_rent_id);
  DBMS_OUTPUT.PUT_LINE('MOD ID: ' || v_mod_id);
  DBMS_OUTPUT.PUT_LINE('Discount: ' || v_discount);
  DBMS_OUTPUT.PUT_LINE('Fine: ' || v_fine);
  DBMS_OUTPUT.PUT_LINE('Total Paid: ' || v_total_paid);
END;

--Archisman Nanda
--This fucntion generates a receipt for a particular customer
--16/12/2024
create or replace FUNCTION GET_RECEIPT(p_customer_id IN VARCHAR2)
RETURN VARCHAR2
IS
  v_receipt VARCHAR2(1000);
  v_customer_name VARCHAR2(100);
  v_rental_id VARCHAR2(20);
  v_start_date DATE;
  v_return_date DATE;
  v_total_paid NUMBER;
  v_rental_exists BOOLEAN := FALSE;
  
  CURSOR rental_cursor IS
    SELECT r.rent_id,r.rent_strt_date,r.rent_ret_date,p.total_paid
    FROM Rentals r
    JOIN Payment p ON r.rent_id=p.rent_id
    where r.customer_id=p_customer_id;
  BEGIN
    v_receipt := '';
     IF NOT REGEXP_LIKE(p_customer_id,'^C(0[0-9][1-9]|0[1-9][0-9]|100)$') THEN
      RAISE_APPLICATION_ERROR(-20002,'Wrong customer ID');
    END IF;
    
  BEGIN 
    SELECT CUSTOMER_NAME
    Into v_customer_name
    FROM customer_master
    where customer_id = p_customer_id;
    
    v_receipt := v_receipt || 'Receipt for Customer:'|| v_customer_name ||CHR(10);
    v_receipt := v_receipt || 'Customer ID: '|| p_customer_id || CHR(10);
    v_receipt := v_receipt || 'Rental Details:'||CHR(10);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 'Customer ID not found';
    END;
    
  OPEN rental_cursor;
  LOOP 
    FETCH rental_cursor INTO v_rental_id,v_start_date,v_return_date, v_total_paid;
    EXIT WHEN rental_cursor%NOTFOUND;
    
    v_rental_exists := TRUE;
    
    v_receipt := v_receipt || 'Rnetal ID: '||v_rental_id||CHR(10);
    v_receipt := v_receipt || 'Start Date: '||TO_CHAR(v_start_date,'DD-MM-YYYY')||CHR(10);
    v_receipt := v_receipt || 'Return Date: '||TO_CHAR(v_return_date,'DD-MM-YYYY')||CHR(10);
    v_receipt := v_receipt || 'Payment Amount: '||v_total_paid||CHR(10);
    
  END LOOP;
  CLOSE rental_cursor;
  IF NOT v_rental_exists THEN
    v_receipt := v_receipt || 'No rentals found for this customer'||CHR(10);
  END IF;
  
  RETURN v_receipt;
  
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'Error: '|| SQLERRM;
    END;
    CREATE SEQUENCE service_id_primary
    START WITH 3
    INCREMENT BY 1;
--Archisman Nanda
--This trigger sends the car for maintenance, changing the vehicle status to 'Getting serviced'
--15/12/2024    
CREATE OR REPLACE TRIGGER send_for_servicing
AFTER UPDATE OF status_of_the_car ON Vehicles
FOR EACH ROW
WHEN (NEW.status_of_the_car = 'Getting Serviced')  
DECLARE
    v_service_description VARCHAR2(255);
    v_service_cost NUMBER(10, 2);
    v_actual_return_date DATE;
BEGIN
    -- Retrieve the actual return date from the Rentals table
    SELECT MAX(actual_return_date)
    INTO v_actual_return_date
    FROM Rentals
    WHERE car_id = :NEW.Car_ID
      AND actual_return_date IS NOT NULL
      AND payment_status = 'Paid';

    -- Randomly select a service description and cost
    CASE FLOOR(DBMS_RANDOM.VALUE(1, 4))
        WHEN 1 THEN
            v_service_description := 'Oil Change and Brake Service';
            v_service_cost := 2000;
        WHEN 2 THEN
            v_service_description := 'Tire Replacement and Alignment';
            v_service_cost := 10000;
        WHEN 3 THEN
            v_service_description := 'Dent and scratches';
            v_service_cost := 8000;
        WHEN 4 THEN
            v_service_description := 'Engine malfunction';
            v_service_cost := 25000;
        ELSE
             v_service_description := 'Come to garage';
            v_service_cost := 500;
           
            
    END CASE;

    -- Insert into Service_Record table
    INSERT INTO Service_Record (Service_ID,Car_ID,Service_Date,Service_status_of_the_car,Service_Cost) 
     VALUES ('S'||LPAD(service_id_primary.NEXTVAL,3,0), -- Generate a unique Service_ID
        :NEW.Car_ID,
        v_actual_return_date + 1, -- Set Service_Date to one day after actual_return_date
        v_service_description,
        v_service_cost
    );
END;
--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------


    exec input_agency('Hyderabad');
    exec input_customer('Archisman Nanda','719 Oak st, Bangalore',9868594874,'archisman.nanda@capgemini.com','A004',TO_DATE('16-12-2024','DD-MM-YYYY'),23);
    
  Select * from Rentals
  where rent_id ='R052';
    exec input_vehicles('Mitshubishi Lancer Evo','Mitshubishi',2011,'Petrol',2,240,'Dangerous');
    
    
    exec input_insurance('V034');
    exec rent_car('A004','C011','V001', TO_DATE('29-12-2024','DD-MM-YYYY'), TO_DATE('2-01-2025','DD-MM-YYYY'));
    exec input_vehicles('Lexus LS','Toyota',2023,'Petrol',5,330,'Available');
    
        exec rent_car('A004','C011','V034', TO_DATE('4-01-2025','DD-MM-YYYY'), TO_DATE('9-01-2025','DD-MM-YYYY'));

    
    exec return_vehicle('V034',TO_DATE('10-01-2025','DD-MM-YYYY'));
    
    exec get_payment_details('R033');
    
  DECLARE
    receipt VARCHAR2(1000);
BEGIN
    receipt := get_receipt('C004');
    DBMS_OUTPUT.PUT_LINE('Receipt of the customer is ' || receipt);
END;

--Archisman Nanda
--This sql query displays the details of the customers who took maximum rentals in a particular year
--16/12/2024    
 WITH yearly_rentals AS (
    SELECT customer_id, EXTRACT(YEAR FROM rent_strt_date) AS rental_year, COUNT(rent_id) AS rental_count
    FROM rentals
    GROUP BY customer_id, EXTRACT(YEAR FROM rent_strt_date)
),
max_rentals AS (
    SELECT rental_year, MAX(rental_count) AS max_rental_count
    FROM yearly_rentals
    GROUP BY rental_year
),
top_customers AS (
    SELECT yr.customer_id, yr.rental_year, yr.rental_count
    FROM yearly_rentals yr
    JOIN max_rentals mr ON yr.rental_year = mr.rental_year AND yr.rental_count = mr.max_rental_count
)
SELECT DISTINCT c.customer_id, c.customer_name, mr.rental_year
FROM customer_master c
JOIN top_customers mr ON c.customer_id = mr.customer_id
ORDER BY mr.rental_year, c.customer_id ;

--Archisman Nanda
--This sql query displays the number of rentals done in particular year of all agencies
--16/12/2024    
SELECT a.agency_id, EXTRACT(YEAR FROM r.rent_strt_date) AS rental_year, COUNT(r.rent_id) AS rental_count
FROM agency a
JOIN rentals r ON a.agency_id = r.agency_id
GROUP BY a.agency_id, EXTRACT(YEAR FROM r.rent_strt_date)
ORDER BY rental_year, a.agency_id;

exec get_rental_details('A002','September');


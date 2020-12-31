// --- USERS --------------------------------------------------------

abstract sig NotifVal {}
one sig Yes, No extends NotifVal {}

sig User {
	notified : NotifVal
}

fact "user is called user because he/she uses the system" {
	all u:User |
	some s:System | u in s.users
}

fact "user should not be notified, when there is no alarm on" {
	all u:User |
	(all a : Alarm | a.state = Off implies u.notified = No)
}

// --- MEASURES ------------------------------------------------

one sig DesiredTemperature {
	minTemp, maxTemp : Int
} { // maximum temperature must exceed the minimum temperature
	all mi:minTemp, ma:maxTemp | mi <= ma 
}

one sig DesiredHumidity {
	minHum, maxHum : Int
} { // maximum temperature must exceed the minimum temperature
	all mi:minHum, ma:maxHum | mi <= ma 
}


// --- SENSORS ------------------------------------------------	

abstract sig Sensor {} {
	// sensor must belong into exactly one room
	one r:Room | this in r.sensors
}

abstract sig Detection {}
one sig Detected, Undetected extends Detection {}

abstract sig Detector extends Sensor {
	detected : Detection
}

sig FireDetector, MotionDetector, WaterDetector, GasDetector extends Detector {}

// --- SENSORS WITH SCALE -----------------------

abstract sig ScaleSensor extends Sensor {
	measuredValue : Int
}

sig TempSensor, HumiditySensor extends ScaleSensor {}

fact "tempSensor should measure the room's temperature" {
	all r:Room, t:TempSensor | t in r.sensors implies t.measuredValue = r.temperature
}

fact "humidSensor should measure the room's humidity" {
	all r:Room, t:HumiditySensor | t in r.sensors implies t.measuredValue = r.humidity
}


// --- APPLIANCE -----------------------------------------------

abstract sig ApplianceState{}
one sig On, Off extends ApplianceState {}

abstract sig Appliance {
	state : one ApplianceState
}

abstract sig UserAppliance, SafetyAppliance extends Appliance {}

fact "user appliance belongs to exactly one room" {
	all a:UserAppliance |
	one r:Room |
		a in r.appliances
}

// --- SPECIFIC APPLIANCES ---------------------------------

// --- APPLIANCES ON/OFF -----------------------------------

pred setOn[a,a':Appliance] {
	a' = a
	a'.state = On
}

pred setOff[a,a':Appliance] {
	a' = a
	a'.state = On
}

// --- safety features ----------------

sig Sprinkler extends SafetyAppliance {}
abstract sig Alarm extends SafetyAppliance {}
sig FireAlarm, GasAlarm extends Alarm {}

// --- fire detector -------------------

fact "fire detected in a building -> set alarm on, set sprinklers in the room on" {
	all b:Building |
	(some r:b.rooms | some f:FireDetector | f in r.sensors and f.detected = Detected)
	implies 
	(b.fireAlarm.state = On &&
	all u:{ us:User | (some s:System | b in s.building and us in s.users) } | u.notified = Yes)
}

fact "fire not in a building(none of the sensors detected fire) -> alarm off" {
	all b:Building |
	(all a:{ f:FireDetector | f in b.rooms.sensors} | a.detected = Undetected)
	implies 
	(b.fireAlarm.state = Off &&
	(all spr : { s:Sprinkler | s in b.rooms.sAppliances} | spr.state = Off)	
	)
}

fact "fire detected in a room -> sprinkler in the room should be on" {
	all r:Room |
	(some fd : { f:FireDetector | f in r.sensors } | fd.detected = Detected)
	implies 
	(all spr : { s:Sprinkler | s in r.sAppliances} | spr.state = On)
}

fact "fire not in a room -> sprinkler should be off" {
	all r:Room |
	(all fd : { f:FireDetector | f in r.sensors } | fd.detected = Undetected)
	implies 
	(all spr : { s:Sprinkler | s in r.sAppliances} | spr.state = Off)
}

fact "fire alarm should not belong to room (it is supposed to belong to a building)" {
	all f:FireAlarm, r:Room |
		f not in r.sAppliances
}

// --- motion detection ---------------------

fact "there is a movement in a building" {
	some md:MotionDetector | md.detected = Detected implies 
	(all u: {us : User | (some s:System | md in s.building.rooms.sensors and us in s.users)} | u.notified = Yes)
}

// --- water detection -----------------------

fact "there is a water in a building" {
	some wd:WaterDetector | wd.detected = Detected implies 
	(all u: {us : User | (some s:System | wd in s.building.rooms.sensors and us in s.users)} | u.notified = Yes)
}

// --- gas detection -------------------------

fact "gas in building detected" {
	all b:Building |
	(	
	(some gd:GasDetector | gd in b.rooms.sensors and gd.detected = Detected) implies	b.gasAlarm.state = On 
	&&
	(all u: {us : User | (some s:System | b in s.building and us in s.users)} | u.notified = Yes)
	)	
}

fact "gas in building detected" {
	all b:Building |
	(all g: {gd:GasDetector | gd in b.rooms.sensors} | g.detected = Undetected) implies b.gasAlarm.state = Off 
}

fact "gas in a room detected -> in the room {open window, start ventilation, start alarm" {
	all r:Room |
	(some gd : { g:GasDetector | g in r.sensors } | gd.detected = Detected)
	implies
	(all wo : { w:WindowOpener | w in r.appliances} | wo.state = On &&
	all ve : { v:Ventilation | v in r.appliances} | ve.state = On)
}

// --- comfort features ----------------------

sig Ventilation, WindowOpener, Shades extends UserAppliance {}

// --- ventilation -----------------------------

fact "when the humidity in the room is above the desired value, the ventilation and open should be o" {
	all r:Room, h:HumiditySensor |
		(h in r.sensors and h.measuredValue > DesiredHumidity.maxHum) implies
		(all v: { ve:Ventilation | ve in r.appliances} | v.state = On &&
		all w: {wi:WindowOpener | wi in r.appliances } | w.state = On)
}

// --- APPLIANCES WITH REGULATION -----------

abstract sig RegulatableAppliance extends UserAppliance {
	value : Int
}

pred increase[a,a':RegulatableAppliance] {
	a' = a
	a'.value = a.value + 1
}

pred decrease[a,a':RegulatableAppliance] {
	a' = a
	a'.value = a.value - 1
}

// --- heating --------------------------------

sig Heater extends RegulatableAppliance {}

fact "room with heater must have a temp sensor" {
	all h:Heater, r:Room |
		h in r.appliances implies
			some t:TempSensor |
				t in r.sensors	
}

fact "when the temperature in the room drops below the desired temp, the heater should be on" {
	all r:Room, t:TempSensor |
		(t in r.sensors and t.measuredValue < DesiredTemperature.minTemp) implies
		(all h: {he:Heater | he in r.appliances} | (h.state = On && h.value >= DesiredTemperature.minTemp) &&
		all w: {wi:WindowOpener | wi in r.appliances } | w.state = Off
		)
}

fact "when the temperature in the room is above the desired temp, the heater should be off" {
	all r:Room, t:TempSensor |
		(t in r.sensors and t.measuredValue > DesiredTemperature.maxTemp) implies
		(all h: {he:Heater | he in r.appliances} | h.state = Off &&
		all w: {wi:WindowOpener | wi in r.appliances } | w.state = On &&
		all s: {sh:Shades | sh in r.appliances } | s.state = On
		)
}



// --- BUILDING -------------------------------------------

sig Room{
	appliances : set UserAppliance,
	sAppliances : set SafetyAppliance,
	sensors : set Sensor,
	temperature, humidity : Int
} 

fact "we are interested only in rooms inside buildings" {
	all r:Room | some b:Building | r in b.rooms
}

fact "room has at least one sprinkler and one fire detector" {
	all r:Room |
		(some s:Sprinkler | s in r.sAppliances) &&
		(some f:FireDetector | f in r.sensors)
}

fact "rooms do not share appliances" {
	all r,r2:Room |
		r != r2 implies 
		(all a : r.appliances | a not in r2.appliances)
		&&
		(all a : r.sAppliances | a not in r2.sAppliances)
}

fact "rooms do not share sensors" {
	all r, r2:Room |
		r != r2 implies 
		all s : r.sensors | s not in r2.sensors
}

pred addUserAppliance[r,r1:Room, a:UserAppliance] {
	r1 = r
	r1.appliances = r.appliances + a
}

pred addSafetyAppliance[r,r1:Room, a:SafetyAppliance] {
	r1 = r
	r1.sAppliances = r.sAppliances + a
}

// --- building ----------------------------

sig Building {
	fireAlarm : one FireAlarm,
	gasAlarm : one GasAlarm,
	rooms : some Room
}

fact "we are interested in buildings using our system" {
	all b:Building | some s:System | b in s.building
}

fact "buildings do not share rooms" {
	all b1,b2:Building |
		b1 != b2 implies
			(all r1 : b1.rooms | r1 not in b2.rooms) &&
			(all a1 : b1.rooms.appliances  | a1 not in b2.rooms.appliances) && 
			(all a1 : b1.rooms.sAppliances  | a1 not in b2.rooms.sAppliances)
}

fact "buildings do not share alarms" {
	all b1,b2:Building |
		b1 != b2 implies
			b1.fireAlarm != b2.fireAlarm
}

sig System{
	building : some Building,
	users : some User
}

// --- TESTING ------------------------------------------

// alarm is on only when there is a gas detected
assert GasAlarmOn {
	some ga:GasAlarm | ga.state = On implies 
		(		
		(some gd:GasDetector | gd.detected = Detected) &&
		(some u:User | u.notified = Yes)
		)
}

// alarm is off, there must not be any gas detector on
assert GasAlarmOff {
	all ga:GasAlarm | ga.state = Off implies 
		not (some gd:GasDetector | gd.detected = Detected)

}

// alarm is on, there must be a fire
assert Fire {
	some fa:FireAlarm | fa.state = On implies
		(		
		(some fd:FireDetector | fd.detected = Detected) &&
		(some u:User | u.notified = Yes) &&
		(some s:Sprinkler | s.state = On)	
		)
}

// alarm is off, there must not be any gas detector on
assert NoFire {
	all fa:FireAlarm | fa.state = Off implies
		not (some fd:FireDetector | fd.detected = Detected)
}

// user should be notified only when there is a problem detected
assert UserNotifiedOk {
	(some u:User | u.notified = Yes) implies
		(
		(some gd:GasDetector | gd.detected = Detected) or
		(some fd:FireDetector | fd.detected = Detected) or
		(some md:MotionDetector | md.detected = Detected) or
		(some wd:WaterDetector | wd.detected = Detected)
		)
}	

assert UserNotifiedNotOk {
	(some u:User | u.notified = Yes) and
		not (
		(some gd:GasDetector | gd.detected = Detected) or
		(some fd:FireDetector | fd.detected = Detected) or
		(some md:MotionDetector | md.detected = Detected) or
		(some wd:WaterDetector | wd.detected = Detected)
		)
}	

// users sould not be notified unless there is a problem detected
assert UsersNotNotified {
	(all u:User | u.notified = No) implies
		not (
		(some gd:GasDetector | gd.detected = Detected) or
		(some fd:FireDetector | fd.detected = Detected) or
		(some md:MotionDetector | md.detected = Detected) or
		(some wd:WaterDetector | wd.detected = Detected)
		)
}	

assert settingOnOk {
	all a,a': Appliance | setOn[a,a'] implies a'.state = On
}

assert settingOnNotOk {
	some a,a': Appliance | setOn[a,a'] and a'.state = Off
}

assert increaseOk {
	all a,a1:RegulatableAppliance | increase[a,a1] implies a.value + 1 = a1.value
}

assert increaseNotOk {
	some a,a1:RegulatableAppliance | increase[a,a1] and a.value + 1 != a1.value
}

assert UserApplianceAddedOk {
	all r,r1:Room, a:UserAppliance | addUserAppliance[r,r1,a] implies a in r1.appliances
}

assert UserApplianceAddedNotOk {
	some r,r1:Room, a:UserAppliance | addUserAppliance[r,r1,a] and not (a in r1.appliances)
}

//check GasAlarmOn
//check GasAlarmOff
//check Fire
//check NoFire
//check UserNotifiedOk
//check UserNotifiedNotOk
//check UsersNotNotified
//check TooHotInside
//check settingOnOk
//check settingOnNotOk
//check increaseOk
//check increaseNotOk
//check UserApplianceAddedOk
//check UserApplianceAddedNotOk

// fact { one r:Room | one d:Detector | d in r.sensors and d.detected = Detected }
// fact { some r:Room | some d:Detector | d in r.sensors and d.detected = Detected }


pred show () {}
run show for 5 but exactly 1 System










const NAV = [
  { group: "Introduction", id: "overview", label: "Dashboard / Overview", icon: "grid" },
  { group: "Introduction", id: "scope", label: "Project Scope", icon: "layers" },
  { group: "Experience", id: "journey", label: "User Journey", icon: "route" },
  { group: "Experience", id: "customer", label: "Customer App", icon: "phone" },
  { group: "Experience", id: "booking", label: "Booking Flow", icon: "calendar" },
  { group: "Booking model", id: "venues", label: "Venue & Court Management", icon: "building" },
  { group: "Booking model", id: "pricing", label: "Pricing & Booking Rules", icon: "tag" },
  { group: "Booking model", id: "availability", label: "Availability & Operating Hours", icon: "clock" },
  { group: "Booking model", id: "payments", label: "Payments", icon: "card" },
  { group: "Booking model", id: "notifications", label: "Notifications", icon: "bell" },
  { group: "Operations", id: "admin", label: "Admin Panel", icon: "shield" },
  { group: "Operations", id: "compare", label: "Existing vs Enhancement vs New", icon: "columns" },
  { group: "Operations", id: "rules", label: "Business Rules", icon: "list" },
  { group: "Delivery", id: "technical", label: "Technical Overview", icon: "cpu" },
  { group: "Delivery", id: "timeline", label: "Timeline / Effort", icon: "flag" },
  { group: "Delivery", id: "decisions", label: "Questions / Decisions", icon: "help" },
  { group: "Demo", id: "prototype", label: "UI Prototype", icon: "device" }
];

const SPORTS = [
  { id: "badminton", name: "Badminton" },
  { id: "cricket", name: "Cricket" },
  { id: "basketball", name: "Basketball" },
  { id: "football", name: "Football" },
  { id: "pickleball", name: "Pickleball" },
  { id: "swimming", name: "Swimming" }
];

const VENUES = [
  {
    id: "thudiyalur",
    name: "Thudiyalur",
    address: "RIAM Sports Arena, Thudiyalur Main Road, Coimbatore, Tamil Nadu 641034",
    mapsUrl: "https://www.google.com/maps/search/?api=1&query=Thudiyalur%2C%20Coimbatore",
    hours: "Open 24 hours",
    blurb: "Full arena. Courts, nets, basketball, turf and pickleball each keep a separate calendar."
  },
  {
    id: "saibaba",
    name: "Saibaba Colony",
    address: "RIAM Sports, Saibaba Colony, Coimbatore, Tamil Nadu 641011",
    mapsUrl: "https://www.google.com/maps/search/?api=1&query=Saibaba%20Colony%2C%20Coimbatore",
    hours: "Hours depend on the sport. Swimming follows a weekly schedule.",
    blurb: "Pickleball courts and the swimming pool. Cricket is not offered at this venue."
  }
];

const MODES = {
  badminton: [
    { id: "person", name: "Per Person", pricing: "person", rate: 150, unit: "person", priceLabel: "₹150 / person", capacity: "Price follows the number of players." }
  ],
  basketball: [
    { id: "half", name: "Half Court", pricing: "hourly", rate: 600, unit: "hour", priceLabel: "₹600 / hour", capacity: "One side of the court." },
    { id: "full", name: "Full Court", pricing: "hourly", rate: 1000, unit: "hour", priceLabel: "₹1,000 / hour", capacity: "The entire court." }
  ],
  swimming: [
    { id: "person", name: "Per Person", pricing: "person", rate: 350, unit: "person", priceLabel: "₹350 / person", capacity: "Shared pool. Price follows headcount." },
    { id: "private", name: "Private Pool", pricing: "session", rate: 3500, unit: "session", priceLabel: "₹3,500 / session", capacity: "The full pool is reserved." }
  ],
  pickleball: [
    { id: "court", name: "Court Rental", pricing: "band", unit: "hour", priceLabel: "Time-band rate", capacity: "One pickleball court." }
  ],
  football: [
    { id: "turf", name: "Turf Rental", pricing: "band", unit: "hour", priceLabel: "Time-band rate", capacity: "Full turf." }
  ],
  cricket: [
    { id: "net", name: "Net Rental", pricing: "tbc", unit: "hour", priceLabel: "Rate to be confirmed", capacity: "One cricket net." }
  ]
};

const BANDS = {
  pickleball: {
    thudiyalur: [
      { start: 6 * 60, end: 18 * 60, rate: 600, label: "6:00 AM – 6:00 PM", sample: false },
      { start: 18 * 60, end: 24 * 60, rate: 800, label: "6:00 PM – 6:00 AM", sample: false }
    ],
    saibaba: [
      { start: 6 * 60, end: 18 * 60, rate: 700, label: "6:00 AM – 6:00 PM", sample: true },
      { start: 18 * 60, end: 24 * 60, rate: 900, label: "6:00 PM – 6:00 AM", sample: true }
    ]
  },
  football: {
    thudiyalur: [
      { start: 0, end: 18 * 60, rate: 800, label: "Before 6:00 PM", sample: false },
      { start: 18 * 60, end: 24 * 60, rate: 1000, label: "After 6:00 PM", sample: false }
    ]
  }
};

const DEFAULT_SWIM = {
  closedDays: [3],
  standard: [
    { start: "08:00", end: "17:00", kind: "open", label: "Available for rental" },
    { start: "17:00", end: "20:00", kind: "class", label: "Classes / non-bookable" },
    { start: "20:00", end: "23:00", kind: "open", label: "Available for rental" }
  ],
  sunday: [
    { start: "08:00", end: "11:00", kind: "open", label: "Available for rental" },
    { start: "11:00", end: "13:00", kind: "class", label: "Classes / non-bookable" },
    { start: "13:00", end: "23:00", kind: "open", label: "Available for rental" }
  ]
};

function buildCourts() {
  const spec = [
    ["thudiyalur", "badminton", 4, "Court"],
    ["thudiyalur", "cricket", 2, "Net"],
    ["thudiyalur", "basketball", 1, "Court"],
    ["thudiyalur", "football", 1, "Turf"],
    ["thudiyalur", "pickleball", 4, "Court"],
    ["saibaba", "pickleball", 2, "Court"],
    ["saibaba", "swimming", 1, "Pool"]
  ];
  const code = { badminton: "bd", cricket: "cr", basketball: "bb", football: "fb", pickleball: "pb", swimming: "sw" };
  const courts = [];
  spec.forEach(([venueId, sportId, count, noun]) => {
    const prefix = venueId === "thudiyalur" ? "td" : "sb";
    for (let i = 1; i <= count; i += 1) {
      courts.push({ id: `${prefix}-${code[sportId]}-${i}`, venueId, sportId, name: `${noun} ${i}`, legacy: false });
    }
  });
  courts.push({
    id: "legacy-bd-2",
    venueId: "thudiyalur",
    sportId: "badminton",
    name: "Legacy service · Badminton Court 2",
    legacy: true,
    historicalBookings: 14
  });
  return courts;
}

const COURTS = buildCourts();

const BOOKINGS = [
  { id: "RIAM-10482", customer: "Arun Kumar", phone: "+91 98430 11220", venueId: "thudiyalur", sportId: "basketball", courtId: "td-bb-1", date: "2026-10-04", start: "18:00", end: "19:00", duration: 60, modeId: "half", side: "A", headcount: 6, amount: 600, paymentStatus: "Paid", bookingStatus: "Confirmed", method: "UPI", createdAt: "28 Sep 2026, 9:14 AM", txn: "pay_demo_10482", gateway: "Razorpay", refund: "None" },
  { id: "RIAM-10490", customer: "Meera S", phone: "+91 97900 44881", venueId: "thudiyalur", sportId: "basketball", courtId: "td-bb-1", date: "2026-10-04", start: "16:00", end: "17:00", duration: 60, modeId: "full", headcount: 10, amount: 1000, paymentStatus: "Paid", bookingStatus: "Confirmed", method: "Card", createdAt: "28 Sep 2026, 4:02 PM", txn: "pay_demo_10490", gateway: "Razorpay", refund: "None" },
  { id: "RIAM-10502", customer: "Karthik R", phone: "+91 90031 77654", venueId: "thudiyalur", sportId: "pickleball", courtId: "td-pb-1", date: "2026-10-04", start: "19:00", end: "20:00", duration: 60, modeId: "court", headcount: 4, amount: 800, paymentStatus: "Paid", bookingStatus: "Confirmed", method: "UPI", createdAt: "29 Sep 2026, 11:20 AM", txn: "pay_demo_10502", gateway: "Razorpay", refund: "None" },
  { id: "RIAM-10510", customer: "Ananya V", phone: "+91 98422 66019", venueId: "saibaba", sportId: "swimming", courtId: "sb-sw-1", date: "2026-10-04", start: "09:00", end: "10:00", duration: 60, modeId: "person", headcount: 4, amount: 1400, paymentStatus: "Paid", bookingStatus: "Confirmed", method: "UPI", createdAt: "29 Sep 2026, 6:40 PM", txn: "pay_demo_10510", gateway: "Razorpay", refund: "None" },
  { id: "RIAM-10331", customer: "Rahul G", phone: "+91 97865 22109", venueId: "thudiyalur", sportId: "football", courtId: "td-fb-1", date: "2026-10-03", start: "17:30", end: "19:00", duration: 90, modeId: "turf", headcount: 12, amount: 1400, paymentStatus: "Paid", bookingStatus: "Confirmed", method: "UPI", createdAt: "27 Sep 2026, 8:05 PM", txn: "pay_demo_10331", gateway: "Razorpay", refund: "None" },
  { id: "RIAM-10220", customer: "Divya P", phone: "+91 99400 31882", venueId: "thudiyalur", sportId: "badminton", courtId: "legacy-bd-2", date: "2026-09-18", start: "07:00", end: "08:00", duration: 60, modeId: "person", headcount: 2, amount: 300, paymentStatus: "Paid", bookingStatus: "Completed", method: "UPI", createdAt: "16 Sep 2026, 7:12 PM", txn: "pay_demo_10220", gateway: "Razorpay", refund: "None", legacy: true },
  { id: "RIAM-10540", customer: "Suresh N", phone: "+91 98941 22008", venueId: "thudiyalur", sportId: "cricket", courtId: "td-cr-1", date: "2026-10-05", start: "06:30", end: "07:30", duration: 60, modeId: "net", headcount: 2, amount: null, paymentStatus: "Pending", bookingStatus: "Pending", method: "—", createdAt: "30 Sep 2026, 1:18 PM", txn: "—", gateway: "Razorpay", refund: "None" },
  { id: "RIAM-10411", customer: "Priya M", phone: "+91 95001 77420", venueId: "saibaba", sportId: "pickleball", courtId: "sb-pb-2", date: "2026-10-02", start: "18:30", end: "19:30", duration: 60, modeId: "court", headcount: 4, amount: 900, paymentStatus: "Paid", bookingStatus: "Confirmed", method: "Card", createdAt: "30 Sep 2026, 9:02 AM", txn: "pay_demo_10411", gateway: "Razorpay", refund: "None", sampleRate: true },
  { id: "RIAM-10102", customer: "Lakshmi T", phone: "+91 93600 44127", venueId: "thudiyalur", sportId: "badminton", courtId: "td-bd-1", date: "2026-10-06", start: "20:00", end: "21:00", duration: 60, modeId: "person", headcount: 4, amount: 600, paymentStatus: "Failed", bookingStatus: "Hold", method: "UPI", createdAt: "30 Sep 2026, 8:44 PM", txn: "pay_demo_10102", gateway: "Razorpay", refund: "None" },
  { id: "RIAM-09940", customer: "Vivek S", phone: "+91 98431 00921", venueId: "thudiyalur", sportId: "basketball", courtId: "td-bb-1", date: "2026-09-21", start: "08:00", end: "09:00", duration: 60, modeId: "half", side: "B", headcount: 5, amount: 600, paymentStatus: "Refunded", bookingStatus: "Cancelled", method: "UPI", createdAt: "19 Sep 2026, 5:16 PM", txn: "pay_demo_09940", gateway: "Razorpay", refund: "Refunded" },
  { id: "RIAM-10555", customer: "Arun Kumar", phone: "+91 98430 11220", venueId: "thudiyalur", sportId: "badminton", courtId: "td-bd-3", date: "2026-10-01", start: "11:00", end: "12:00", duration: 60, modeId: "person", headcount: 4, amount: 600, paymentStatus: "Paid", bookingStatus: "Confirmed", method: "UPI", createdAt: "30 Sep 2026, 6:10 PM", txn: "pay_demo_10555", gateway: "Razorpay", refund: "None" },
  { id: "RIAM-10560", customer: "Nikhil J", phone: "+91 88700 15443", venueId: "thudiyalur", sportId: "pickleball", courtId: "td-pb-3", date: "2026-10-08", start: "06:30", end: "07:30", duration: 60, modeId: "court", headcount: 4, amount: 600, paymentStatus: "Processing", bookingStatus: "Pending", method: "UPI", createdAt: "1 Oct 2026, 10:05 AM", txn: "pay_demo_10560", gateway: "Razorpay", refund: "None" }
];

const FLOW = ["Customer", "Select Location", "Select Sport", "Select Court", "Select Date", "Select Time Slot", "Select Booking Mode", "Review Price", "Payment", "Booking Confirmation"];

const KEY_CHANGES = [
  { title: "Sport → Court hierarchy", type: "new", text: "A sport contains courts or resources. Customers book a specific court." },
  { title: "Individual court calendars", type: "new", text: "Each court keeps its own availability. Booking one court leaves the others open." },
  { title: "Multiple booking modes", type: "new", text: "Half court, full court, per person and private pool can carry different prices." },
  { title: "Operating hours and closures", type: "new", text: "Weekly closed days and class blocks can be marked non-bookable." },
  { title: "Time-based pricing", type: "enhance", text: "Hourly pricing already exists. Rates now change across defined time bands." },
  { title: "Headcount-based pricing", type: "new", text: "Per-person sports calculate the amount from the number of participants." },
  { title: "Group discounts", type: "new", text: "Swimming groups of five or more use the ₹300 rate, with a code path from eight." },
  { title: "Variable slot duration", type: "new", text: "Customers can book 30 minutes, 1 hour or 1.5 hours." },
  { title: "Phone OTP login", type: "new", text: "Google login stays. Phone and OTP are added so WhatsApp has a verified number." },
  { title: "Live Razorpay payment", type: "enhance", text: "The integration exists. The account needs to move from test to production." },
  { title: "Exact Google Maps navigation", type: "new", text: "Get Directions opens the Maps link stored for that venue." },
  { title: "Transaction API access", type: "new", text: "External booking reads can include payment and refund fields." }
];

const SCOPE = {
  existing: ["Location management", "Dynamic sports and services", "Location and sport filtering", "Date and time selection", "Real-time availability", "Slot blocking", "Booking summary", "Pricing breakdown", "Google OAuth", "Customer profile", "Razorpay integration", "Booking confirmation", "Booking history", "Turf Town integration", "Admin management", "WhatsApp notifications"],
  enhance: ["Venue-specific pricing", "Slot availability visualization", "Google Maps direction links", "Production Razorpay configuration", "Sport icon mapping"],
  bugs: ["Sport / venue assignment does not stay removed", "Sport icons follow list position", "Booked and past slots resemble open slots"],
  fresh: ["Sport → court / resource hierarchy", "Individual court calendars", "Booking modes", "Operating hours", "Closure schedules", "Class and non-bookable periods", "Time-band pricing", "Headcount pricing", "Group discounts", "Discount codes", "Variable slot durations", "Phone OTP", "Transaction API access"]
};

const TRACKER = [
  { item: "Sport management", current: "Sports and services are configurable.", required: "Keep sport management, and place courts beneath each sport.", type: "existing", priority: "—", status: "Covered" },
  { item: "Venue management", current: "Locations can be created and filtered.", required: "Keep venues, and attach courts and a Maps link to each one.", type: "existing", priority: "—", status: "Covered" },
  { item: "Sport → court hierarchy", current: "Booking is location, then service.", required: "Sport, then court or resource, then booking mode.", type: "new", priority: "High", status: "Open" },
  { item: "Individual court calendar", current: "Availability sits on the service.", required: "Every physical court has its own calendar and capacity.", type: "new", priority: "High", status: "Open" },
  { item: "Booking mode", current: "A service has one booking pattern.", required: "Modes such as half court, full court, per person and private pool.", type: "new", priority: "High", status: "Open" },
  { item: "Legacy service migration", current: "Separate services were created as a workaround for courts.", required: "Map those services into the new structure and keep every historical booking.", type: "new", priority: "High", status: "Open" },
  { item: "Sport / venue assignment", current: "Unchecking a venue shows success, then the venue returns and stays bookable.", required: "Removing a venue removes it from discovery and from new bookings.", type: "bug", priority: "High", status: "Reported" },
  { item: "Opening hours", current: "Slots are offered without a stored operating-hour rule.", required: "Each resource can define when rental is allowed.", type: "new", priority: "High", status: "Open" },
  { item: "Weekly closures", current: "A weekly closed day is not a configured rule.", required: "A day such as Wednesday for Saibaba swimming stays closed.", type: "new", priority: "High", status: "Open" },
  { item: "Hour-wise pricing", current: "The approved scope includes hour-wise pricing.", required: "Retain hourly pricing as the base for the new bands.", type: "existing", priority: "—", status: "Covered" },
  { item: "Time-band pricing", current: "Hour-wise pricing is described, without day and evening bands.", required: "A time range can carry its own rate.", type: "enhance", priority: "High", status: "Open" },
  { item: "Venue-specific pricing", current: "Location-wise pricing is in the original scope. The form applies one price to every venue on a sport.", required: "Sport + venue + time band can each hold a separate price.", type: "enhance", priority: "High", status: "Open" },
  { item: "Per-person pricing", current: "The booking records a slot and a price breakdown, without participant quantity.", required: "Capture headcount and multiply the per-person rate.", type: "new", priority: "High", status: "Open" },
  { item: "Group discount", current: "No group-size price rule is defined.", required: "Swimming groups of 5 or more pay ₹300 per person.", type: "new", priority: "High", status: "Open" },
  { item: "Discount code", current: "No coupon or discount code is defined.", required: "A group of 8 can apply a configured discount code.", type: "new", priority: "Medium", status: "Open" },
  { item: "Variable slot duration", current: "The slot picker is hourly.", required: "Offer 30 minutes, 1 hour and 1.5 hours, and keep the list configurable.", type: "new", priority: "High", status: "Open" },
  { item: "Google login", current: "Customers sign in with Google.", required: "Keep Google sign-in.", type: "existing", priority: "—", status: "Covered" },
  { item: "Phone OTP login", current: "Authentication is Google only. Mobile is collected on the profile.", required: "Add phone number and OTP as a sign-in method.", type: "new", priority: "High", status: "Open" },
  { item: "Mobile number", current: "The customer profile already asks for a mobile number.", required: "Use that verified number for WhatsApp reminders.", type: "existing", priority: "—", status: "Covered" },
  { item: "Slot availability", current: "Real-time availability and slot blocking are in scope.", required: "Keep live availability, now evaluated per court.", type: "existing", priority: "—", status: "Covered" },
  { item: "Booked and past slots", current: "Unavailable slots can look similar to open slots.", required: "Booked, past, closed and class each have a distinct state and a reason.", type: "ui", priority: "Medium", status: "Open" },
  { item: "Sport icons", current: "Badminton shows a football icon, cricket shows basketball, football shows cricket.", required: "Choose the icon from the sport itself.", type: "bug", priority: "Medium", status: "Reported" },
  { item: "Location and maps", current: "Customers can discover a location. Directions are not tied to a stored pin.", required: "Show the venue and offer Get Directions from the stored Maps URL.", type: "enhance", priority: "Medium", status: "Open" },
  { item: "Exact Maps URL", current: "A pinned Google Maps URL is not a stored admin field.", required: "Admin saves the exact link. The app opens that link.", type: "new", priority: "Medium", status: "Open" },
  { item: "Razorpay", current: "Checkout, success, failure and callbacks are in scope.", required: "Keep the payment module.", type: "existing", priority: "—", status: "Covered" },
  { item: "Razorpay production", current: "The connector is on a trial / test configuration.", required: "Activate the live connector and validate a production payment.", type: "enhance", priority: "High", status: "Open" },
  { item: "Booking API", current: "Booked slots and open slots can be read.", required: "Keep slot reads, and extend them where the new resource model requires it.", type: "enhance", priority: "Medium", status: "Open" },
  { item: "Transaction API", current: "Payment webhooks exist. Transaction fields are not part of the booking read API.", required: "Expose the agreed payment fields to the booking API.", type: "new", priority: "High", status: "Open" }
];

const JOURNEY = [
  { id: "login", title: "Login", text: "The customer continues with Google or verifies a mobile number by OTP. WhatsApp reminders use that number." },
  { id: "location", title: "Select location", text: "Thudiyalur and Saibaba Colony are the two venues. Each card shows what can actually be booked there." },
  { id: "sport", title: "Select sport", text: "Only sports assigned to the chosen venue appear. Cricket stays off the Saibaba list." },
  { id: "court", title: "Select court", text: "The customer picks a physical court, net, turf or pool. Each one has its own next available time." },
  { id: "date", title: "Select date", text: "The calendar belongs to the selected court. A closed day can still be opened so the reason is visible." },
  { id: "slots", title: "View available slots", text: "Open, booked, past, closed and class periods are visually separate, and each blocked state explains why." },
  { id: "duration", title: "Select duration", text: "30 minutes, 1 hour or 1.5 hours rebuilds the slot list. A slot that would cross a class or closing is blocked." },
  { id: "mode", title: "Select booking mode", text: "The mode sets price and capacity. Full court and private pool reserve the whole resource." },
  { id: "people", title: "Enter headcount", text: "Per-person modes ask how many people are playing. One person and six people produce different totals." },
  { id: "discount", title: "Apply discount", text: "Swimming groups of five move to ₹300 per person. A group of eight can enter a discount code." },
  { id: "price", title: "Review price", text: "The summary shows venue, court, time, mode, headcount, band rates, discount and the final amount." },
  { id: "pay", title: "Pay", text: "Razorpay collects the payment. The review shows pending, processing, success and failed states." },
  { id: "confirm", title: "Booking confirmation", text: "A booking ID is issued with the court, time and amount. The customer can view or download it." },
  { id: "whatsapp", title: "WhatsApp notification", text: "The confirmation message repeats the booking details and includes the stored directions link." },
  { id: "history", title: "View booking history", text: "Upcoming and completed bookings stay visible, including bookings made on a legacy service." }
];

const RULES = [
  { n: "01", title: "Independent court calendars", text: "Each court, net, turf and pool has its own availability. Schedules are not shared across courts of the same sport." },
  { n: "02", title: "One court does not block another", text: "A booking on Badminton Court 1 leaves Courts 2, 3 and 4 open at the same time." },
  { n: "03", title: "Mode sets the price", text: "Half court, full court, per person and private pool resolve to the rate configured for that mode." },
  { n: "04", title: "Price can vary by venue, court and time", text: "A rate belongs to a sport, a venue, a court when needed, a mode and a time range." },
  { n: "05", title: "Closed periods cannot be booked", text: "A weekly closure, such as swimming on Wednesday at Saibaba, offers no rental slots." },
  { n: "06", title: "Class periods cannot be booked", text: "Teaching blocks stay visible and are marked non-bookable, with the class hours as the reason." },
  { n: "07", title: "Past slots cannot be booked", text: "A time that has already started or ended stays visible and cannot be selected for payment." },
  { n: "08", title: "Headcount is required for per-person prices", text: "Badminton at ₹150 and swimming at ₹350 calculate from the number of participants." },
  { n: "09", title: "Group discounts follow the configured rule", text: "Five or more swimmers use ₹300 per person. Eight or more can apply the discount code configured by admin." },
  { n: "10", title: "Existing bookings remain valid", text: "Moving from separate services to courts does not rewrite or drop bookings already made." },
  { n: "11", title: "Deactivated legacy records stay", text: "A legacy service referenced by a past booking is deactivated, never deleted." },
  { n: "12", title: "A phone number is required for OTP and WhatsApp", text: "Google sign-in can continue. The verified mobile number is still required before reminders are sent." }
];

const AUDIENCES = [
  { title: "Customer", text: "Finds a venue, chooses a court and pays for a time that is actually open." },
  { title: "Venue manager", text: "Maintains courts, modes, hours, closures, prices and the Maps link." },
  { title: "Accounts", text: "Reviews payments, refunds and the transaction fields shared through the API." }
];

const ADMIN_MODULES = [
  ["Venues", "Address, hours summary and the exact Maps URL."],
  ["Sports", "Sports offered by the business, with a fixed icon."],
  ["Courts", "Create, edit, assign and deactivate without deleting history."],
  ["Booking modes", "Half court, full court, per person, private pool and rentals."],
  ["Pricing", "Rates scoped by venue, court, mode and time range."],
  ["Availability", "Court calendars and slot holds."],
  ["Operating hours", "When a resource can be rented."],
  ["Closures", "Weekly closed days."],
  ["Classes", "Non-bookable teaching blocks."],
  ["Bookings", "The operational register of every reservation."],
  ["Customers", "Profile, mobile number and booking history."],
  ["Payments", "Status, method, gateway reference and refund."],
  ["Discounts", "Group-size rates and discount codes."],
  ["Notifications", "WhatsApp confirmation, reminder and cancellation."],
  ["Reports", "Bookings and collections for a period."],
  ["API / integrations", "Razorpay, WhatsApp, Maps, Turf Town and the booking API."],
  ["Settings", "Roles, payment mode and organisation profile."]
];

const TIMELINE = [
  {
    n: "1",
    title: "Sport, venue, court and booking mode",
    complexity: "High",
    dependencies: "Admin structure, customer booking, availability, pricing and existing bookings all sit on this model.",
    migration: "High. Legacy services are mapped into courts. Historical bookings keep their original reference.",
    testing: "High. Court isolation, modes, capacity and Turf Town synchronisation need a dedicated pass.",
    note: "Migration and data validation should be estimated as their own task inside this area."
  },
  {
    n: "2",
    title: "Availability, operating hours and pricing",
    complexity: "High",
    dependencies: "Depends on the court model. Includes closures, class blocks, time bands, headcount, discounts and duration.",
    migration: "Medium. Existing prices need a home on the new venue, court and time-band rules.",
    testing: "High. Every blocked reason and every price combination needs cases, including slots that cross 6:00 PM.",
    note: "This is the largest pricing change in the request."
  },
  {
    n: "3",
    title: "Booking, payment and API enhancements",
    complexity: "Medium–High",
    dependencies: "Depends on the price quote, live Razorpay credentials and an agreed transaction field list.",
    migration: "Low to medium. Payment history stays attached to existing booking records.",
    testing: "High. Test and live payment paths, webhooks, refunds and API consumers need validation.",
    note: "OTP, Maps links, slot visuals and icon corrections travel with this delivery stream."
  }
];

const DECISIONS = [
  { id: "structure", title: "Final court and resource structure", detail: "Confirm the courts at Thudiyalur and Saibaba, including names and which sports exist at each venue.", status: "clarify" },
  { id: "modes", title: "Booking modes for each sport", detail: "Confirm half / full court, per person, private pool, and whether any other sport needs more than one mode.", status: "clarify" },
  { id: "pricing", title: "Pricing rules", detail: "Confirm time bands, venue differences and any court-level exceptions. Saibaba pickleball rates in this review are samples.", status: "pending" },
  { id: "hours", title: "Operating hours", detail: "Confirm Thudiyalur’s 24-hour operation and the rental windows for every resource, especially swimming.", status: "pending" },
  { id: "closures", title: "Closure periods", detail: "Confirm Wednesday as a full closure for Saibaba swimming, and any other weekly closures.", status: "pending" },
  { id: "classes", title: "Class and non-bookable periods", detail: "Confirm the weekday 5:00–8:00 PM block and the Sunday 11:00 AM–1:00 PM block.", status: "pending" },
  { id: "group", title: "Group discount rules", detail: "Confirm that 5 or more swimmers pay ₹300 per person, and whether any other sport has a group rate.", status: "clarify" },
  { id: "code", title: "Discount code rules", detail: "Confirm the code, the discount value and whether it stacks with the 5+ rate. The ₹200 value in this review is a sample.", status: "clarify" },
  { id: "otp", title: "OTP provider", detail: "Choose the SMS or WhatsApp OTP provider and the sender identity.", status: "pending" },
  { id: "razorpay", title: "Live Razorpay credentials", detail: "Provide the live key, webhook secret and the production callback URL. Test mode stays until those are in place.", status: "pending" },
  { id: "maps", title: "Google Maps links", detail: "Paste the exact pinned URL for Thudiyalur and for Saibaba Colony.", status: "pending" },
  { id: "turftown", title: "Turf Town API access", detail: "Confirm credentials and how court-level availability should synchronise with Turf Town.", status: "clarify" },
  { id: "txn", title: "Transaction API requirements", detail: "Confirm the field list, who consumes it, and which booking statuses are included.", status: "clarify" }
];

const API_FIELDS = [
  ["bookingId", "Booking ID"],
  ["txnId", "Transaction ID"],
  ["paymentId", "Payment ID"],
  ["amount", "Amount"],
  ["paymentStatus", "Payment status"],
  ["method", "Payment method"],
  ["bookingStatus", "Booking status"],
  ["paidAt", "Transaction date and time"],
  ["refund", "Refund status"]
];

const PROTO_SCREENS = [
  ["login", "Login", "customer"],
  ["home", "Home", "customer"],
  ["location", "Location selection", "customer"],
  ["sport", "Sport selection", "customer"],
  ["court", "Court selection", "customer"],
  ["calendar", "Calendar", "customer"],
  ["slots", "Time slots", "customer"],
  ["mode", "Booking mode", "customer"],
  ["headcount", "Headcount", "customer"],
  ["summary", "Price summary", "customer"],
  ["payment", "Payment", "customer"],
  ["success", "Booking success", "customer"],
  ["history", "Booking history", "customer"],
  ["venue", "Venue details", "customer"],
  ["admin-home", "Admin dashboard", "admin"],
  ["admin-venues", "Venue management", "admin"],
  ["admin-courts", "Court management", "admin"],
  ["admin-pricing", "Pricing management", "admin"],
  ["admin-availability", "Availability management", "admin"],
  ["admin-bookings", "Booking management", "admin"],
  ["admin-transactions", "Transaction management", "admin"],
  ["admin-reports", "Reports", "admin"]
];

const SLIDES = [
  { id: "problem", kicker: "Problem", title: "Customers need to book a court, not a generic service." },
  { id: "current", kicker: "Current system", title: "The approved scope already covers the core booking platform." },
  { id: "changes", kicker: "Required changes", title: "The new request is a resource-aware booking engine." },
  { id: "architecture", kicker: "New booking architecture", title: "Sport, venue, court, mode, then price and time." },
  { id: "flow", kicker: "User flow", title: "A customer can see why a slot is open or blocked." },
  { id: "pricing", kicker: "Pricing", title: "Price depends on venue, time, mode and headcount." },
  { id: "availability", kicker: "Availability", title: "Hours, weekly closures and classes are booking rules." },
  { id: "payment", kicker: "Payment", title: "Razorpay stays. Production activation is the change." },
  { id: "admin", kicker: "Admin", title: "Managers control courts, rates, hours and payments." },
  { id: "migration", kicker: "Migration", title: "Old court-services move across. Their bookings stay." },
  { id: "technical", kicker: "Technical architecture", title: "One application layer, with the services already in scope." },
  { id: "timeline", kicker: "Timeline", title: "Three areas are the serious scope. Days come after validation." },
  { id: "final", kicker: "Final scope", title: "Confirm the open decisions, then the estimate can be closed." }
];

const REVENUE = [
  { label: "Mon", value: 18400 },
  { label: "Tue", value: 22100 },
  { label: "Wed", value: 12600 },
  { label: "Thu", value: 24800 },
  { label: "Fri", value: 31200 },
  { label: "Sat", value: 46800 },
  { label: "Sun", value: 39500 }
];

const BADGE_TIPS = {
  new: "Not defined as its own requirement in the original document.",
  enhance: "The idea exists in the original scope and needs a deeper implementation.",
  bug: "Current behaviour needs a correction.",
  existing: "Already covered in the original approved scope.",
  ui: "Availability exists. The change is how the state is shown."
};

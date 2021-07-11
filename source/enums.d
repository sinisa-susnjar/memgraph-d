/// Enumerations
module enums;

/// Types that can be stored in a `Value`.
enum Type {
	Null,
	Bool,
	Int,
	Double,
	String,
	List,
	Map,
	Node,
	Relationship,
	UnboundRelationship,
	Path,
	Date,
	Time,
	LocalTime,
	DateTime,
	DateTimeZoneId,
	LocalDateTime,
	Duration,
	Point2d,
	Point3d
}

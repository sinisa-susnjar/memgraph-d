/// Enumerations
module memgraph.enums;

/// An enum listing all the types as specified by the Bolt protocol.
enum Type {
  /// Represents the absence of a value.
  Null,
  /// Boolean true or false.
  Bool,
  /// 64-bit signed integer.
  Int,
  /// 64-bit floating point number.
  Double,
  /// UTF-8 encoded string.
  String,
  /// Ordered collection of values.
  List,
  /// Unordered, keyed collection of values.
  Map,
  /// A node in a Property Graph with optional properties and labels.
  Node,
  /// A directed, typed connection between two nodes in a Property Graph.
  /// Each relationship may have properties and always has an identity.
  Relationship,
  /// Like `Relationship`, but without identifiers for start and end nodes.
  /// Mainly used as a supporting type for `Path`. An unbound relationship
  /// owns its type string and property map.
  UnboundRelationship,
  /// The record of a directed walk through a Property Graph, consisting of a sequence of zero or more segments.
  Path,
  /// Date is defined with number of days since the Unix epoch.
  Date,
  /// Represents local time.
  /// Time is defined with nanoseconds since midnight.
  LocalTime,
  /// Represents date and time without its time zone.
  /// Date is defined with seconds since the Unix epoch.
  /// Time is defined with nanoseconds since midnight.
  LocalDateTime,
  /// Represents a temporal amount which captures the difference in time
  /// between two instants.
  /// Duration is defined with months, days, seconds, and nanoseconds.
  /// Note: Duration can be negative.
  Duration,
  /// Represents a single location in 2-dimensional space.
  /// Contains SRID along with its x and y coordinates.
  Point2d,
  /// Represents a single location in 3-dimensional space.
  /// Contains SRID along with its x, y and z coordinates.
  Point3d
}

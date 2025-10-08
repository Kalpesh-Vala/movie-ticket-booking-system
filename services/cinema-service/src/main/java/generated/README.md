# Generated Protocol Buffer Files

This directory contains the generated Java classes from Protocol Buffer definitions located in `/proto/cinema.proto`.

## Generated Files

### CinemaServiceGrpc.java
- **Purpose**: gRPC service stub classes for client-server communication
- **Generated From**: `cinema.proto` service definitions
- **Contains**: 
  - Service interface definitions
  - Client stub classes (blocking, async, future)
  - Server base classes for implementation

### CinemaServiceProto.java
- **Purpose**: Protocol Buffer message classes and builders
- **Generated From**: `cinema.proto` message definitions  
- **Contains**:
  - Message classes (CinemaInfo, MovieInfo, SeatInfo, etc.)
  - Builder patterns for message construction
  - Serialization/deserialization methods

## Regeneration Instructions

If you modify the `proto/cinema.proto` file, regenerate these files using:

```bash
# Clean and regenerate
mvn clean compile

# Copy updated files to source directory
cp -r target/generated-sources/protobuf/java/* src/main/java/generated/
cp -r target/generated-sources/protobuf/grpc-java/* src/main/java/generated/
```

## Why These Files Are Committed

These generated files are included in version control to:

1. **Simplify Deployment**: Other developers don't need Protocol Buffer compiler setup
2. **Consistent Builds**: Ensures identical generated code across environments  
3. **CI/CD Compatibility**: Automated builds work without protobuf toolchain
4. **Docker Builds**: Container builds work without additional protobuf dependencies

## Maven Configuration

The build process uses:
- **protobuf-maven-plugin**: Generates files in `target/generated-sources/`
- **build-helper-maven-plugin**: Includes `src/main/java/generated/` as source directory

This dual approach ensures the service works both in development (with generation) and production (with committed files).

## File Structure

```
src/main/java/generated/
└── com/
    └── movieticket/
        └── cinema/
            └── grpc/
                ├── CinemaServiceGrpc.java    # gRPC service stubs
                └── CinemaServiceProto.java   # Protocol Buffer messages
```

## Dependencies

These files depend on:
- `io.grpc:grpc-stub` - gRPC client/server infrastructure
- `io.grpc:grpc-protobuf` - Protocol Buffer integration
- `com.google.protobuf:protobuf-java` - Protocol Buffer runtime

All dependencies are managed in the parent `pom.xml` file.
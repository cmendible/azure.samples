FROM mcr.microsoft.com/dotnet/sdk:6.0-bullseye-slim AS build-env
WORKDIR /app

# Copy necessary files and restore as distinct layer
COPY CameraControlService.csproj ./
RUN dotnet restore

# Copy everything else and build
COPY . ./
RUN dotnet publish -c Release -o out CameraControlService.csproj

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:6.0-bullseye-slim
COPY --from=build-env /app/out .

# Start
ENTRYPOINT ["dotnet", "CameraControlService.dll"]
FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build
WORKDIR /src

# Copy csproj and restore as distinct layers
COPY signalr.server.csproj .
RUN dotnet restore

# Copy everything else and build website
COPY . .
RUN dotnet publish -c release

# Final stage / image
FROM mcr.microsoft.com/dotnet/aspnet:5.0
COPY --from=build /src/bin/release/net5.0/publish ./
ENTRYPOINT ["dotnet", "signalr.server.dll"]
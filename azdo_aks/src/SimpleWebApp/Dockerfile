FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

# Copy csproj and restore as distinct layers
COPY SimpleWebApp.csproj .
RUN dotnet restore

# Copy everything else and build website
COPY . .
RUN dotnet publish -c release

# Final stage / image
FROM mcr.microsoft.com/dotnet/aspnet:6.0
COPY --from=build /src/bin/release/net6.0/publish ./
ENTRYPOINT ["dotnet", "SimpleWebApp.dll"]
using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace MunicipalElections.Api.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "AspNetRoles",
                columns: table => new
                {
                    Id = table.Column<string>(type: "TEXT", nullable: false),
                    Name = table.Column<string>(type: "TEXT", maxLength: 256, nullable: true),
                    NormalizedName = table.Column<string>(type: "TEXT", maxLength: 256, nullable: true),
                    ConcurrencyStamp = table.Column<string>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetRoles", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "AspNetUsers",
                columns: table => new
                {
                    Id = table.Column<string>(type: "TEXT", nullable: false),
                    FullName = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    UserName = table.Column<string>(type: "TEXT", maxLength: 256, nullable: true),
                    NormalizedUserName = table.Column<string>(type: "TEXT", maxLength: 256, nullable: true),
                    Email = table.Column<string>(type: "TEXT", maxLength: 256, nullable: true),
                    NormalizedEmail = table.Column<string>(type: "TEXT", maxLength: 256, nullable: true),
                    EmailConfirmed = table.Column<bool>(type: "INTEGER", nullable: false),
                    PasswordHash = table.Column<string>(type: "TEXT", nullable: true),
                    SecurityStamp = table.Column<string>(type: "TEXT", nullable: true),
                    ConcurrencyStamp = table.Column<string>(type: "TEXT", nullable: true),
                    PhoneNumber = table.Column<string>(type: "TEXT", nullable: true),
                    PhoneNumberConfirmed = table.Column<bool>(type: "INTEGER", nullable: false),
                    TwoFactorEnabled = table.Column<bool>(type: "INTEGER", nullable: false),
                    LockoutEnd = table.Column<DateTimeOffset>(type: "TEXT", nullable: true),
                    LockoutEnabled = table.Column<bool>(type: "INTEGER", nullable: false),
                    AccessFailedCount = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUsers", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Municipalities",
                columns: table => new
                {
                    MunicipalityId = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Name = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    Province = table.Column<string>(type: "TEXT", maxLength: 50, nullable: false),
                    ElectionDate = table.Column<DateOnly>(type: "TEXT", nullable: false),
                    Description = table.Column<string>(type: "TEXT", maxLength: 1000, nullable: true),
                    LogoUrl = table.Column<string>(type: "TEXT", maxLength: 500, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Municipalities", x => x.MunicipalityId);
                });

            migrationBuilder.CreateTable(
                name: "AspNetRoleClaims",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    RoleId = table.Column<string>(type: "TEXT", nullable: false),
                    ClaimType = table.Column<string>(type: "TEXT", nullable: true),
                    ClaimValue = table.Column<string>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetRoleClaims", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AspNetRoleClaims_AspNetRoles_RoleId",
                        column: x => x.RoleId,
                        principalTable: "AspNetRoles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AspNetUserClaims",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    UserId = table.Column<string>(type: "TEXT", nullable: false),
                    ClaimType = table.Column<string>(type: "TEXT", nullable: true),
                    ClaimValue = table.Column<string>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUserClaims", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AspNetUserClaims_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AspNetUserLogins",
                columns: table => new
                {
                    LoginProvider = table.Column<string>(type: "TEXT", nullable: false),
                    ProviderKey = table.Column<string>(type: "TEXT", nullable: false),
                    ProviderDisplayName = table.Column<string>(type: "TEXT", nullable: true),
                    UserId = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUserLogins", x => new { x.LoginProvider, x.ProviderKey });
                    table.ForeignKey(
                        name: "FK_AspNetUserLogins_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AspNetUserRoles",
                columns: table => new
                {
                    UserId = table.Column<string>(type: "TEXT", nullable: false),
                    RoleId = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUserRoles", x => new { x.UserId, x.RoleId });
                    table.ForeignKey(
                        name: "FK_AspNetUserRoles_AspNetRoles_RoleId",
                        column: x => x.RoleId,
                        principalTable: "AspNetRoles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_AspNetUserRoles_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AspNetUserTokens",
                columns: table => new
                {
                    UserId = table.Column<string>(type: "TEXT", nullable: false),
                    LoginProvider = table.Column<string>(type: "TEXT", nullable: false),
                    Name = table.Column<string>(type: "TEXT", nullable: false),
                    Value = table.Column<string>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUserTokens", x => new { x.UserId, x.LoginProvider, x.Name });
                    table.ForeignKey(
                        name: "FK_AspNetUserTokens_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Positions",
                columns: table => new
                {
                    PositionId = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Name = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    SeatsAvailable = table.Column<int>(type: "INTEGER", nullable: false),
                    MunicipalityId = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Positions", x => x.PositionId);
                    table.ForeignKey(
                        name: "FK_Positions_Municipalities_MunicipalityId",
                        column: x => x.MunicipalityId,
                        principalTable: "Municipalities",
                        principalColumn: "MunicipalityId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Candidates",
                columns: table => new
                {
                    CandidateId = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Name = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    Biography = table.Column<string>(type: "TEXT", maxLength: 4000, nullable: true),
                    PhotoUrl = table.Column<string>(type: "TEXT", maxLength: 500, nullable: true),
                    Website = table.Column<string>(type: "TEXT", maxLength: 500, nullable: true),
                    Email = table.Column<string>(type: "TEXT", maxLength: 256, nullable: true),
                    PositionId = table.Column<int>(type: "INTEGER", nullable: false),
                    MunicipalityId = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Candidates", x => x.CandidateId);
                    table.ForeignKey(
                        name: "FK_Candidates_Municipalities_MunicipalityId",
                        column: x => x.MunicipalityId,
                        principalTable: "Municipalities",
                        principalColumn: "MunicipalityId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Candidates_Positions_PositionId",
                        column: x => x.PositionId,
                        principalTable: "Positions",
                        principalColumn: "PositionId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "SavedCandidates",
                columns: table => new
                {
                    SavedCandidateId = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    UserId = table.Column<string>(type: "TEXT", nullable: false),
                    CandidateId = table.Column<int>(type: "INTEGER", nullable: false),
                    DateSaved = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SavedCandidates", x => x.SavedCandidateId);
                    table.ForeignKey(
                        name: "FK_SavedCandidates_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_SavedCandidates_Candidates_CandidateId",
                        column: x => x.CandidateId,
                        principalTable: "Candidates",
                        principalColumn: "CandidateId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "Municipalities",
                columns: new[] { "MunicipalityId", "Description", "ElectionDate", "LogoUrl", "Name", "Province" },
                values: new object[,]
                {
                    { 1, "A small city in Metro Vancouver between the Pitt and Fraser rivers, known for its farmland, dyke trails and regional airport.", new DateOnly(2026, 10, 17), "https://ui-avatars.com/api/?name=Pitt%20Meadows&size=256&background=2E7D32&color=fff&format=png&bold=true", "Pitt Meadows", "British Columbia" },
                    { 2, "A growing city on the north side of the Fraser River at the foot of the Golden Ears mountains.", new DateOnly(2026, 10, 17), "https://ui-avatars.com/api/?name=Maple%20Ridge&size=256&background=1565C0&color=fff&format=png&bold=true", "Maple Ridge", "British Columbia" },
                    { 3, "Metro Vancouver's third-largest city, home to Metrotown, Simon Fraser University and BCIT.", new DateOnly(2026, 10, 17), "https://ui-avatars.com/api/?name=Burnaby&size=256&background=6A1B9A&color=fff&format=png&bold=true", "Burnaby", "British Columbia" }
                });

            migrationBuilder.InsertData(
                table: "Positions",
                columns: new[] { "PositionId", "MunicipalityId", "Name", "SeatsAvailable" },
                values: new object[,]
                {
                    { 1, 1, "Mayor", 1 },
                    { 2, 1, "Councillor", 6 },
                    { 3, 1, "School Trustee", 2 },
                    { 4, 2, "Mayor", 1 },
                    { 5, 2, "Councillor", 6 },
                    { 6, 2, "School Trustee", 5 },
                    { 7, 3, "Mayor", 1 },
                    { 8, 3, "Councillor", 8 },
                    { 9, 3, "School Trustee", 7 }
                });

            migrationBuilder.InsertData(
                table: "Candidates",
                columns: new[] { "CandidateId", "Biography", "Email", "MunicipalityId", "Name", "PhotoUrl", "PositionId", "Website" },
                values: new object[,]
                {
                    { 1, "Two-term councillor and former small-business owner focused on protecting farmland and improving the Harris Road underpass traffic flow.", "elena.marsh@example.com", 1, "Elena Marsh", "https://ui-avatars.com/api/?name=Elena%20Marsh&size=256&background=0D8ABC&color=fff&format=png", 1, "https://example.com/elena.marsh" },
                    { 2, "Civil engineer and Pitt Meadows Day volunteer running on infrastructure renewal and a balanced budget.", "raj.sandhu@example.com", 1, "Raj Sandhu", "https://ui-avatars.com/api/?name=Raj%20Sandhu&size=256&background=0D8ABC&color=fff&format=png", 1, "https://example.com/raj.sandhu" },
                    { 3, "Registered nurse campaigning for expanded seniors' services and more family doctors in the community.", "megan.oleary@example.com", 1, "Megan O'Leary", "https://ui-avatars.com/api/?name=Megan%20O%27Leary&size=256&background=0D8ABC&color=fff&format=png", 2, "https://example.com/megan.oleary" },
                    { 4, "Youth soccer coach advocating for new recreation facilities and safer cycling routes along the dykes.", "thomas.nguyen@example.com", 1, "Thomas Nguyen", "https://ui-avatars.com/api/?name=Thomas%20Nguyen&size=256&background=0D8ABC&color=fff&format=png", 2, "https://example.com/thomas.nguyen" },
                    { 5, "Parent advisory council chair committed to smaller class sizes and school meal programs.", "priya.kaur@example.com", 1, "Priya Kaur", "https://ui-avatars.com/api/?name=Priya%20Kaur&size=256&background=0D8ABC&color=fff&format=png", 3, "https://example.com/priya.kaur" },
                    { 6, "Retired teacher with 30 years in SD 42 classrooms, focused on literacy and special-education support.", "daniel.fraser@example.com", 1, "Daniel Fraser", "https://ui-avatars.com/api/?name=Daniel%20Fraser&size=256&background=0D8ABC&color=fff&format=png", 3, "https://example.com/daniel.fraser" },
                    { 7, "Former city planner promising faster housing approvals and a revitalized downtown core.", "samantha.cole@example.com", 2, "Samantha Cole", "https://ui-avatars.com/api/?name=Samantha%20Cole&size=256&background=0D8ABC&color=fff&format=png", 4, "https://example.com/samantha.cole" },
                    { 8, "Local entrepreneur running on property-tax restraint, public safety and support for local business.", "marcus.bell@example.com", 2, "Marcus Bell", "https://ui-avatars.com/api/?name=Marcus%20Bell&size=256&background=0D8ABC&color=fff&format=png", 4, "https://example.com/marcus.bell" },
                    { 9, "Environmental scientist championing park protection around Golden Ears and Kanaka Creek.", "aisha.rahman@example.com", 2, "Aisha Rahman", "https://ui-avatars.com/api/?name=Aisha%20Rahman&size=256&background=0D8ABC&color=fff&format=png", 5, "https://example.com/aisha.rahman" },
                    { 10, "Firefighter and union steward focused on emergency preparedness and wildfire resilience.", "kevin.brooks@example.com", 2, "Kevin Brooks", "https://ui-avatars.com/api/?name=Kevin%20Brooks&size=256&background=0D8ABC&color=fff&format=png", 5, "https://example.com/kevin.brooks" },
                    { 11, "Early-childhood educator advocating for full-day child care spaces in schools.", "linda.park@example.com", 2, "Linda Park", "https://ui-avatars.com/api/?name=Linda%20Park&size=256&background=0D8ABC&color=fff&format=png", 6, "https://example.com/linda.park" },
                    { 12, "Software developer pushing for modern technology and digital-literacy programs across SD 42.", "jordan.ellis@example.com", 2, "Jordan Ellis", "https://ui-avatars.com/api/?name=Jordan%20Ellis&size=256&background=0D8ABC&color=fff&format=png", 6, "https://example.com/jordan.ellis" },
                    { 13, "Three-term councillor focused on affordable rental housing near SkyTrain stations.", "victor.chen@example.com", 3, "Victor Chen", "https://ui-avatars.com/api/?name=Victor%20Chen&size=256&background=0D8ABC&color=fff&format=png", 7, "https://example.com/victor.chen" },
                    { 14, "Community-centre director running on accessible recreation, libraries and transit.", "grace.morales@example.com", 3, "Grace Morales", "https://ui-avatars.com/api/?name=Grace%20Morales&size=256&background=0D8ABC&color=fff&format=png", 7, "https://example.com/grace.morales" },
                    { 15, "SFU urban-studies lecturer advocating for complete, walkable neighbourhoods.", "hassan.ali@example.com", 3, "Hassan Ali", "https://ui-avatars.com/api/?name=Hassan%20Ali&size=256&background=0D8ABC&color=fff&format=png", 8, "https://example.com/hassan.ali" },
                    { 16, "Small-business owner on Hastings Street focused on reducing red tape and supporting local shops.", "olivia.wright@example.com", 3, "Olivia Wright", "https://ui-avatars.com/api/?name=Olivia%20Wright&size=256&background=0D8ABC&color=fff&format=png", 8, "https://example.com/olivia.wright" },
                    { 17, "BCIT graduate and climate-action organizer calling for more bike lanes and urban tree canopy.", "ben.tanaka@example.com", 3, "Ben Tanaka", "https://ui-avatars.com/api/?name=Ben%20Tanaka&size=256&background=0D8ABC&color=fff&format=png", 8, "https://example.com/ben.tanaka" },
                    { 18, "Parent and ESL instructor focused on newcomer student support and seismic school upgrades.", "sofia.petrov@example.com", 3, "Sofia Petrov", "https://ui-avatars.com/api/?name=Sofia%20Petrov&size=256&background=0D8ABC&color=fff&format=png", 9, "https://example.com/sofia.petrov" },
                    { 19, "Accountant and former PAC treasurer promising transparent budgets for SD 41.", "michael.osei@example.com", 3, "Michael Osei", "https://ui-avatars.com/api/?name=Michael%20Osei&size=256&background=0D8ABC&color=fff&format=png", 9, "https://example.com/michael.osei" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_AspNetRoleClaims_RoleId",
                table: "AspNetRoleClaims",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "RoleNameIndex",
                table: "AspNetRoles",
                column: "NormalizedName",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUserClaims_UserId",
                table: "AspNetUserClaims",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUserLogins_UserId",
                table: "AspNetUserLogins",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUserRoles_RoleId",
                table: "AspNetUserRoles",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "EmailIndex",
                table: "AspNetUsers",
                column: "NormalizedEmail");

            migrationBuilder.CreateIndex(
                name: "UserNameIndex",
                table: "AspNetUsers",
                column: "NormalizedUserName",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Candidates_MunicipalityId",
                table: "Candidates",
                column: "MunicipalityId");

            migrationBuilder.CreateIndex(
                name: "IX_Candidates_Name",
                table: "Candidates",
                column: "Name");

            migrationBuilder.CreateIndex(
                name: "IX_Candidates_PositionId",
                table: "Candidates",
                column: "PositionId");

            migrationBuilder.CreateIndex(
                name: "IX_Positions_MunicipalityId",
                table: "Positions",
                column: "MunicipalityId");

            migrationBuilder.CreateIndex(
                name: "IX_SavedCandidates_CandidateId",
                table: "SavedCandidates",
                column: "CandidateId");

            migrationBuilder.CreateIndex(
                name: "IX_SavedCandidates_UserId_CandidateId",
                table: "SavedCandidates",
                columns: new[] { "UserId", "CandidateId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AspNetRoleClaims");

            migrationBuilder.DropTable(
                name: "AspNetUserClaims");

            migrationBuilder.DropTable(
                name: "AspNetUserLogins");

            migrationBuilder.DropTable(
                name: "AspNetUserRoles");

            migrationBuilder.DropTable(
                name: "AspNetUserTokens");

            migrationBuilder.DropTable(
                name: "SavedCandidates");

            migrationBuilder.DropTable(
                name: "AspNetRoles");

            migrationBuilder.DropTable(
                name: "AspNetUsers");

            migrationBuilder.DropTable(
                name: "Candidates");

            migrationBuilder.DropTable(
                name: "Positions");

            migrationBuilder.DropTable(
                name: "Municipalities");
        }
    }
}

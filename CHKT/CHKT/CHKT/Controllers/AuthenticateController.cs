using CHKT.Models;
using Microsoft.AspNetCore.Mvc;

namespace CHKT.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthenticateController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public AuthenticateController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpPost("login")]
        public IActionResult Login([FromBody] LoginModel model)
        {
            // Logic hash password, check DB và sinh JWT token ở đây
            return Ok(new { Message = "Login thành công" });
        }

        [HttpPost("register")]
        public IActionResult Register([FromBody] RegistrationModel model)
        {
            // Logic lưu User mới vào DB
            return Ok(new { Message = "Đăng ký thành công" });
        }
    }
}
using CHKT.Models;
using CHKT.Repositories;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace CHKT.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DeviceApiController : ControllerBase
    {
        private readonly IDeviceRepository _deviceRepository;

        public DeviceApiController(IDeviceRepository deviceRepository)
        {
            _deviceRepository = deviceRepository; // Tiêm dependency (DI)
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var devices = await _deviceRepository.GetAllDevicesAsync();
            return Ok(devices);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] Device device)
        {
            await _deviceRepository.AddDeviceAsync(device);
            return Ok(new { Message = "Thêm thiết bị thành công" });
        }
    }
}
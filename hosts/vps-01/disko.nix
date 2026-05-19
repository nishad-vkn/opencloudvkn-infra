{ ... }:

{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";

        content = {
          type = "gpt";

          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
              priority = 1;
            };

            swap = {
              size = "4G";
              content = {
                type = "swap";
                randomEncryption = false;
              };
            };

            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [
                  "defaults"
                  "noatime"
                ];
              };
            };
          };
        };
      };
    };
  };
}

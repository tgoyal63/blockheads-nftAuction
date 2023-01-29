// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract SpamReports {
    struct Report {
        address reporter;
        string ip;
        string description;
        string evidenceHash;
        uint256 timestamp;
    }

    struct Appeal {
        address reporter;
        string ip;
        string description;
        uint256 timestamp;
    }

    struct IP {
        string ip;
        uint256 score;
        bool isBlocked;
    }

    mapping(string => IP) public ipList;
    mapping(string => Report[]) public reports;
    mapping(string => Appeal[]) public appeals;

    function reportSpam(
        string memory _ip,
        string memory _description,
        string memory _evidenceHash
    ) public {
        require(msg.sender != address(0));
        require(
            keccak256(abi.encodePacked(_ip)) != keccak256(abi.encodePacked(""))
        );
        require(
            keccak256(abi.encodePacked(_description)) !=
                keccak256(abi.encodePacked(""))
        );
        require(
            keccak256(abi.encodePacked(_evidenceHash)) !=
                keccak256(abi.encodePacked(""))
        );

        // check if IP already exists in the list
        IP storage ip = ipList[_ip];
        if (
            keccak256(abi.encodePacked(ip.ip)) ==
            keccak256(abi.encodePacked(""))
        ) {
            ip.ip = _ip;
            ip.score = 1;
        } else {
            uint256 i = reports[_ip].length - 1;
            if (reports[_ip][i].timestamp + 1 hours > block.timestamp) {
                revert(
                    "We received a report few moments ago. Please try again later."
                );
            }
            ip.score++;
        }

        // check if IP score exceeds threshold for blocking
        if (ip.score >= 5) {
            ip.isBlocked = true;
        }

        // add report to the list
        Report memory report = Report({
            reporter: msg.sender,
            ip: _ip,
            description: _description,
            evidenceHash: _evidenceHash,
            timestamp: block.timestamp
        });
        reports[_ip].push(report);
    }

    function appeal(string memory _ip, string memory _description) public {
        require(
            keccak256(abi.encodePacked(_ip)) != keccak256(abi.encodePacked(""))
        );
        require(
            keccak256(abi.encodePacked(_description)) !=
                keccak256(abi.encodePacked(""))
        );
        IP storage ip = ipList[_ip];

        if (ip.score == 0) {
            revert("IP not found in the list");
        }
        uint256 i = appeals[_ip].length - 1;
        if (appeals[_ip][i].timestamp + 1 hours > block.timestamp) {
            revert(
                "We received an appeal few moments ago. Please try again later."
            );
        }

        // decrease the score
        ip.score--;

        if (ip.score < 5) {
            ip.isBlocked = false;
        }

        Appeal memory appealRequest = Appeal({
            reporter: msg.sender,
            ip: _ip,
            description: _description,
            timestamp: block.timestamp
        });
        appeals[_ip].push(appealRequest);
    }

    function getIpScore(string memory _ip) public view returns (uint256, bool) {
        IP storage ip = ipList[_ip];
        return (ip.score, ip.isBlocked);
    }

    function getReports(string memory _ip)
        public
        view
        returns (Report[] memory)
    {
        return reports[_ip];
    }

    function getAppeals(string memory _ip)
        public
        view
        returns (Appeal[] memory)
    {
        return appeals[_ip];
    }
}

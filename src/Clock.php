<?php

declare(strict_types=1);

namespace Resoul\Clock;

use DateTimeImmutable;
use DateTimeZone;

final class Clock implements ClockInterface
{
    public function now(): DateTimeImmutable
    {
        return new DateTimeImmutable(timezone: new DateTimeZone('UTC'));
    }
}

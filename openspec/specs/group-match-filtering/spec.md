# group-match-filtering Specification

## Purpose
Defines how group match inclusion is computed from team and stage filters, and how filter changes reconcile the group match list.

## Requirements


### Requirement: Group match inclusion uses union of team and stage filters
For a group, a match SHALL be included if at least one of these conditions is true:
- the homeTeamId is in the group selected teamIds, OR
- the awayTeamId is in the group selected teamIds, OR
- the match stage is in the group selected stages.

#### Scenario: Team-selected match is included
- **WHEN** a match has homeTeamId in the group teamIds
- **THEN** the match is included in the group match list even if its stage is not selected

#### Scenario: Stage-selected match is included
- **WHEN** a match stage is in the group stages
- **THEN** the match is included even if neither team is in the selected teamIds

### Requirement: Group match list updates when filter changes
When an admin updates the group filter, the system MUST reconcile the group match list to add newly included matches and remove only matches that are safe to remove.

#### Scenario: Newly included matches are added
- **WHEN** the group filter is updated and causes a future match to become included
- **THEN** the system creates/activates that match in the group match list

#### Scenario: Matches after lock cannot be removed
- **WHEN** the group filter is updated and a match is no longer included but has passed prediction lock OR is live/finished
- **THEN** the match remains in the group history and is not removed

### Requirement: Removed matches are soft-excluded
Matches that are removed due to filter changes before lock SHALL be soft-excluded rather than hard-deleted, to preserve auditability.

#### Scenario: Excluded match is hidden from primary feed
- **WHEN** a match is marked as excludedByFilter=true
- **THEN** the match is not shown in the default “upcoming/live” feed


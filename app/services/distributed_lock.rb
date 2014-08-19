# This file adapted from
# https://github.com/discourse/discourse/blob/9147af1d62c30dbc1f22ef4c576cd499cc50b100/lib/distributed_mutex.rb
# under the terms of the GPL V3 (see below).
#
# Copyright 2014 Civilized Discourse Construction Kit, Inc.
#
# Licensed under the GNU General Public License Version 2.0 (or
# later); you may not use this work except in compliance with the
# License. You may obtain a copy of the License in the LICENSE file,
# or at:
#
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied. See the License for the specific language governing
# permissions and limitations under the License.

class DistributedLock
  def initialize(key)
    @key = key
    @redis = $redis
  end

  def synchronize
    begin
      while !acquire_lock
        sleep 0.001
      end

      yield

    ensure
      @redis.del(@key)
    end
  end

private
  def acquire_lock
    if @redis.setnx(@key, Time.now.to_i + 20)
      @redis.expire(@key, 20)
      return true
    else
      # Confirm that current value isn't stale
      begin
        @redis.watch(@key)
        @redis.get(@key).to_i < Time.now.to_i && !!@redis.multi do
          @redis.set(@key, Time.now.to_i + 20)
        end
      ensure
        @redis.unwatch
      end
    end
  end
end
